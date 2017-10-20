//
//  ViewController.m
//  BreakPointResume
//
//  Created by 王战胜 on 2017/10/19.
//  Copyright © 2017年 gocomtech. All rights reserved.
//

#import "ViewController.h"
#define Picture_Url @"http://map.onegreen.net/%E4%B8%AD%E5%9B%BD%E6%94%BF%E5%8C%BA2500.jpg"

#define BAKit_ShowAlertWithMsg(msg) UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"温馨提示" message:msg preferredStyle:UIAlertControllerStyleAlert];\
UIAlertAction *sureAction = [UIAlertAction actionWithTitle:@"确 定" style:UIAlertActionStyleDefault handler:nil];\
[alert addAction:sureAction];\
[self presentViewController:alert animated:YES completion:nil];

@interface ViewController ()
@property (nonatomic, strong) NSString *cachePath;
@property(nonatomic , strong) AFHTTPRequestOperation* requestOperation;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    AFNetworkReachabilityManager *manager = [AFNetworkReachabilityManager sharedManager];
   
    /*! 2.设置网络状态改变后的处理 */
    [manager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        /*! 当网络状态改变了, 就会调用这个block */
        switch (status)
        {
            case AFNetworkReachabilityStatusUnknown:
            {
                BAKit_ShowAlertWithMsg(@"无网络");
                break;
            }
            case AFNetworkReachabilityStatusNotReachable:
            {
                BAKit_ShowAlertWithMsg(@"没有网络");
                break;
            }
            case AFNetworkReachabilityStatusReachableViaWWAN:
            {
                BAKit_ShowAlertWithMsg(@"手机自带网络");
                break;
            }
            case AFNetworkReachabilityStatusReachableViaWiFi:
            {
                BAKit_ShowAlertWithMsg(@"wifi 网络");
                break;
            }
        }
    }];
    [manager startMonitoring];
    [self createUI];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)createUI{
    
    
    UIButton *btn=[UIButton buttonWithType:UIButtonTypeCustom];
    btn.backgroundColor=[UIColor redColor];
    [btn addTarget:self action:@selector(download) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    [btn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view).offset(30);
        make.centerY.equalTo(self.view).offset(50);
        make.size.mas_equalTo(CGSizeMake(100, 100));
    }];
}
- (void)download{
    [self downFileFromServer];
}

- (void)downFileFromServer{
    UIImageView *imageView = [[UIImageView alloc]initWithFrame:CGRectMake(50, 50, 200, 200)];
    imageView.backgroundColor = [UIColor redColor];
    
    [self.view addSubview:imageView];
    __weak typeof(self) weakself = self;
    self.cachePath=[NSHomeDirectory() stringByAppendingString:@"/Documents/temp0"];
    //获取缓存的长度
    long long cacheLength = [[self class] cacheFileWithPath:self.cachePath];
    
    NSLog(@"cacheLength = %llu",cacheLength);
    
    //获取请求
    NSMutableURLRequest* request = [[self class] requestWithUrl:Picture_Url Range:cacheLength];
    
    
    self.requestOperation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [self.requestOperation setOutputStream:[NSOutputStream outputStreamToFileAtPath:self.cachePath append:NO]];
    
    //处理流
    [self readCacheToOutStreamWithPath:self.cachePath];
    
    
    [self.requestOperation addObserver:self forKeyPath:@"isPaused" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
    
    //重组进度block
    [self.requestOperation setDownloadProgressBlock:[self getNewProgressBlockWithCacheLength:cacheLength]];
    
    // 下载进度回调
    [self.requestOperation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        
    
        // 下载进度
       NSLog(@"正在下载%.02f %llu %llu",((float)totalBytesRead +(float)cacheLength)/((float)totalBytesExpectedToRead + (float)cacheLength),totalBytesRead + cacheLength,totalBytesExpectedToRead + cacheLength);
        NSData* data = [NSData dataWithContentsOfFile:weakself.cachePath];
        UIImage *iamge=[UIImage imageWithData:data];
        [imageView setImage:iamge];
    }];
    
    // 成功和失败回调
    [self.requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSLog(@"1");
//        successBlock(operation, responseObject);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        NSLog(@"2");
//        failureBlock(operation, error);
    }];
    
    [self.requestOperation start];

}

#pragma mark - 获取本地缓存的字节
+(long long)cacheFileWithPath:(NSString*)path
{
    NSFileHandle* fh = [NSFileHandle fileHandleForReadingAtPath:path];
    
    NSData* contentData = [fh readDataToEndOfFile];
    return contentData ? contentData.length : 0;
    
}

//拼接Request
+(NSMutableURLRequest*)requestWithUrl:(id)url Range:(long long)length
{
    NSURL* requestUrl = [url isKindOfClass:[NSURL class]] ? url : [NSURL URLWithString:url];
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:requestUrl
                                                           cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                       timeoutInterval:5*60];
    
    
    if (length) {
        [request setValue:[NSString stringWithFormat:@"bytes=%lld-",length] forHTTPHeaderField:@"Range"];
    }
    
    NSLog(@"request.head = %@",request.allHTTPHeaderFields);
    
    return request;
    
}

#pragma mark - 读取本地缓存入流
-(void)readCacheToOutStreamWithPath:(NSString*)path
{
    NSFileHandle* fh = [NSFileHandle fileHandleForReadingAtPath:path];
    NSData* currentData = [fh readDataToEndOfFile];
    
    if (currentData.length) {
        //打开流，写入data ， 未打卡查看 streamCode = NSStreamStatusNotOpen
        [self.requestOperation.outputStream open];
        
        NSInteger       bytesWritten;
        NSInteger       bytesWrittenSoFar;
        
        NSInteger  dataLength = [currentData length];
        const uint8_t * dataBytes  = [currentData bytes];
        
        bytesWrittenSoFar = 0;
        do {
            bytesWritten = [self.requestOperation.outputStream write:&dataBytes[bytesWrittenSoFar] maxLength:dataLength - bytesWrittenSoFar];
            assert(bytesWritten != 0);
            if (bytesWritten == -1) {
                break;
            } else {
                bytesWrittenSoFar += bytesWritten;
            }
        } while (bytesWrittenSoFar != dataLength);
        
        
    }
}

#pragma mark - 监听暂停
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    NSLog(@"keypath = %@ changeDic = %@",keyPath,change);
    //暂停状态
    if ([keyPath isEqualToString:@"isPaused"] && [[change objectForKey:@"new"] intValue] == 1) {
        
        
        
        long long cacheLength = [[self class] cacheFileWithPath:self.cachePath];
        //暂停读取data 从文件中获取到NSNumber
        cacheLength = [[self.requestOperation.outputStream propertyForKey:NSStreamFileCurrentOffsetKey] unsignedLongLongValue];
        NSLog(@"cacheLength = %lld",cacheLength);
        [self.requestOperation setValue:@"0" forKey:@"totalBytesRead"];
        //重组进度block
        [self.requestOperation setDownloadProgressBlock:[self getNewProgressBlockWithCacheLength:cacheLength]];
    }
}

#pragma mark - 重组进度块
-(void(^)(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead))getNewProgressBlockWithCacheLength:(long long)cachLength
{
    typeof(self)newSelf = self;
    void(^newProgressBlock)(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) = ^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead)
    {
        NSData* data = [NSData dataWithContentsOfFile:self.cachePath];
        [self.requestOperation setValue:data forKey:@"responseData"];
        //        self.requestOperation.responseData = ;
//        newSelf.progressBlock(bytesRead,totalBytesRead + cachLength,totalBytesExpectedToRead + cachLength);
    };
    
    return newProgressBlock;
}



@end
