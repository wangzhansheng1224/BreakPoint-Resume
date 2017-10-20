//
//  ViewController.m
//  BreakPointResume
//
//  Created by 王战胜 on 2017/10/19.
//  Copyright © 2017年 gocomtech. All rights reserved.
//

#import "ViewController.h"

#define BAKit_ShowAlertWithMsg(msg) UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"温馨提示" message:msg preferredStyle:UIAlertControllerStyleAlert];\
UIAlertAction *sureAction = [UIAlertAction actionWithTitle:@"确 定" style:UIAlertActionStyleDefault handler:nil];\
[alert addAction:sureAction];\
[self presentViewController:alert animated:YES completion:nil];

@interface ViewController ()
{
    // 下载句柄
    NSURLSessionDownloadTask *_downloadTask;
}
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
    
    //远程地址
    NSURL *URL = [NSURL URLWithString:@"http://www.baidu.com/img/bdlogo.png"];
    //默认配置
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    
    //AFN3.0+基于封住URLSession的句柄
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    
    //请求
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    
    //下载Task操作
    _downloadTask = [manager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        
        // @property int64_t totalUnitCount;     需要下载文件的总大小
        // @property int64_t completedUnitCount; 当前已经下载的大小
        
        // 给Progress添加监听 KVO
        NSLog(@"%f",1.0 * downloadProgress.completedUnitCount / downloadProgress.totalUnitCount);
        // 回到主队列刷新UI
        dispatch_async(dispatch_get_main_queue(), ^{
            // 设置进度条的百分比
            
            //            self.progressView.progress = 1.0 * downloadProgress.completedUnitCount / downloadProgress.totalUnitCount;
        });
        
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        
        //- block的返回值, 要求返回一个URL, 返回的这个URL就是文件的位置的路径
        
        NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
        NSString *path = [cachesPath stringByAppendingPathComponent:response.suggestedFilename];
        return [NSURL fileURLWithPath:path];
        
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        //设置下载完成操作
        NSLog(@"2");
        // filePath就是你下载文件的位置，你可以解压，也可以直接拿来使用
        
        //        NSString *imgFilePath = [filePath path];// 将NSURL转成NSString
        //        UIImage *img = [UIImage imageWithContentsOfFile:imgFilePath];
        //        self.imageView.image = img;
        
    }];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
