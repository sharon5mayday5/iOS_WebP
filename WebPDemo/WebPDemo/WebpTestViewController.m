//
//  WebpTestViewController.m
//  kopak
//
//  Created by songshan on 2017/7/27.
//  Copyright © 2017年 BeiJing Cai Yun Corp. All rights reserved.
//

#import "WebpTestViewController.h"
#import "SDWebImageManager.h"
#import "UIImageView+WebCache.h"
#import "UIImage+MultiFormat.h"
#import "UIImage+WebP.h"

@interface WebpTestViewController ()<UIWebViewDelegate>
@property (nonatomic,strong)UIWebView *webv;
@property (nonatomic,strong)NSMutableDictionary *webpImageUrlDic;
@end

@implementation WebpTestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self createWebpView];
    [self createWebView];
}

- (void)createWebpView{
    //视图加载webp图片
    UIView *webpView = [[UIView alloc] initWithFrame:CGRectMake(10, 80, 320, 100)];
    webpView.backgroundColor = [UIColor yellowColor];
    [self.view addSubview:webpView];
    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:@"http://mmbiz.qpic.cn/mmbiz_jpg/AZQZ9KUtamupibEQMmFDLqqsU7RLEvH5h5sPcyZEvhv6tQ5y3WAYKYibeQfnOtQulul5QHFHpL9b0icCKliajWFe2A/640?wx_fmt=jpeg&tp=webp&wxfrom=5&wx_lazy=1"]];
    UIImageView *wpimage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
#ifdef SD_WEBP
    [wpimage setImage:[UIImage sd_imageWithWebPData:data]];
#endif
    [webpView addSubview:wpimage];
}

- (void)createWebView{
    UIWebView *web = [[UIWebView alloc]initWithFrame:CGRectMake(0, 180+50, self.view.frame.size.width, self.view.frame.size.height-180)];
    [web sizeToFit];
//    [web loadHTMLString:@"http://h5test.caiyu.in/webp.html" baseURL:nil];
    [web loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://h5test.caiyu.in/webp.html"]]];
    web.delegate = self;
    web.dataDetectorTypes = UIDataDetectorTypeAll;
    self.webv = web;
    [self.view addSubview:web];
}

//第一种方法  如果用第二种方法，可注释掉这个函数
- (void)webViewDidFinishLoad:(UIWebView *)webView{
    //--------------------------------JS协作的测试-----------------------------------
    //获取`HTML`代码
    NSString *lJs = @"document.documentElement.innerHTML";
    NSString *str = [webView stringByEvaluatingJavaScriptFromString:lJs];
    //执行约定好的方法,获取需要下载的 webp 图片
    NSString *imgs = [webView stringByEvaluatingJavaScriptFromString:@"YongChe.getAllWebPImg();"];
    NSArray *array = [NSJSONSerialization JSONObjectWithData:[imgs dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    
    _webpImageUrlDic = [NSMutableDictionary dictionaryWithCapacity:3];
    for (NSString *imgUrl in array) {
        //检查本地图片缓存
        NSString *key = [[SDWebImageManager sharedManager] cacheKeyForURL:[NSURL URLWithString:imgUrl]];
        NSString *localPath = [[SDImageCache sharedImageCache] defaultCachePathForKey:key];
        NSString *newSrc = imgUrl;
        BOOL localExsit = [[NSFileManager defaultManager] fileExistsAtPath:localPath];
        if (localExsit) {
            newSrc = [NSString stringWithFormat:@"file://%@", localPath];
        }
        //存储webp图片和原图片，如果newSrc和webp相同则说明本地没有缓存图片
        [_webpImageUrlDic setObject:imgUrl forKey:newSrc];
    }
    
    //处理webp格式加载
    [_webpImageUrlDic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if([obj isEqualToString:key]){//说明这图没有缓存，还需要下载
            [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:[NSURL URLWithString:obj] options:0 progress:nil completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished) {
                if (image&&finished) {
                    NSString *js;
                    NSRange range = [[obj lowercaseString] rangeOfString:@".gif"];//检查是否是gif
                    BOOL isGif = (range.location != NSNotFound);
                    if (!isGif) {
                        [[SDImageCache sharedImageCache] storeImage:image forKey:obj];
                        NSString *base64 = [UIImageJPEGRepresentation(image,1) base64EncodedStringWithOptions:0];
                        js = [NSString stringWithFormat:@"YongChe.replaceWebPImg('%@','data:image/png;base64,%@')",obj,base64];
                    }else{//gif的图片如果直接存储，会变成jpg从而失去动画，因此要特殊处理
                        [[SDImageCache sharedImageCache] storeImage:image recalculateFromImage:false imageData:data forKey:obj toDisk:true];
                        NSString *base64 = [data base64EncodedStringWithOptions:0];
                        js = [NSString stringWithFormat:@"YongChe.replaceWebPImg('%@','data:image/gif;base64,%@')",obj,base64];
                    }
                    dispatch_async(dispatch_get_main_queue(), ^{
                        //更新UI操作
                        [self.webv stringByEvaluatingJavaScriptFromString:js];
                    });
                }
            }];
        } else {
            //缓存中存在，那么直接加载吧
            NSString *js;
            NSRange range = [[obj lowercaseString] rangeOfString:@".gif"];//检查是否是gif
            NSData* data = [NSData dataWithContentsOfFile:[key stringByReplacingOccurrencesOfString:@"file://" withString:@""]];
            NSString *base64 = [data base64EncodedStringWithOptions:0];
            BOOL isGif = (range.location != NSNotFound);
            if (!isGif) {
                js = [NSString stringWithFormat:@"YongChe.replaceWebPImg('%@','data:image/png;base64,%@')",obj,base64];
            }else{
                js = [NSString stringWithFormat:@"YongChe.replaceWebPImg('%@','data:image/gif;base64,%@')",obj,base64];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                //更新UI操作
                [self.webv stringByEvaluatingJavaScriptFromString:js];
            });
        }
    }];
}

@end
