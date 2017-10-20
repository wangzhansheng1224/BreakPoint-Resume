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
    
    NSString *path1 = [NSHomeDirectory() stringByAppendingString:[NSString stringWithFormat:@"/Documents/半塘.mp4"]];
    NSString *url = @"http://static.yizhibo.com/pc_live/static/video.swf?onPlay=YZB.play&onPause=YZB.pause&onSeek=YZB.seek&scid=pALRs7JBtTRU9TWy";
    NSURLRequest *downloadRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", @"text/html", @"text/css", @"text/xml", @"text/plain", @"application/javascript", @"application/x-www-form-urlencoded", @"image/*", nil];
     NSURLSessionTask *sessionTask = nil;

    
    sessionTask = [manager downloadTaskWithRequest:downloadRequest progress:^(NSProgress * _Nonnull downloadProgress) {
        NSLog(@"下载进度：%.2lld%%",100 * downloadProgress.completedUnitCount/downloadProgress.totalUnitCount);
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        if (!path1)
        {
            NSURL *downloadURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
            NSLog(@"默认路径--%@",downloadURL);
            return [downloadURL URLByAppendingPathComponent:[response suggestedFilename]];
        }
        else
        {
            return [NSURL fileURLWithPath:path1];
        }
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        NSLog(@"下载文件成功");
        NSLog(@"下载完成，路径为：%@", filePath);
    }];
    
    [sessionTask resume];

}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
