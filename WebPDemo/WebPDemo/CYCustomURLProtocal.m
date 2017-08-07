//
//  CYCustomURLProtocal.m
//  kopak
//
//  Created by songshan on 2017/8/1.
//  Copyright © 2017年 BeiJing Cai Yun Corp. All rights reserved.
//

#import "CYCustomURLProtocal.h"
#import "UIImage+WebP.h"

static NSString *URLProtocolHandledKey = @"URLHasHandle";

@interface CYCustomURLProtocal()<NSURLSessionDelegate,NSURLSessionDataDelegate>

@property (nonatomic,strong) NSURLSession *session;

@end

@implementation CYCustomURLProtocal

#pragma mark 初始化请求

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    //只处理http和https请求
    NSString *scheme = [[request URL] scheme];
    NSString *extension = [[request URL] pathExtension];
    if (([scheme caseInsensitiveCompare:@"http"] == NSOrderedSame || [scheme caseInsensitiveCompare:@"https"] == NSOrderedSame) && ([extension caseInsensitiveCompare:@"webp"] == NSOrderedSame)) {
        //看看是否已经处理过了，防止无限循环
        if ([NSURLProtocol propertyForKey:URLProtocolHandledKey inRequest:request]) {
            return NO;
        }
        return YES;
    }
    return NO;
}

+ (NSURLRequest *) canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

#pragma mark 通信协议内容实现

- (void)startLoading
{
    NSMutableURLRequest *mutableReqeust = [[self request] mutableCopy];
    //标示改request已经处理过了，防止无限循环
    [NSURLProtocol setProperty:@YES forKey:URLProtocolHandledKey inRequest:mutableReqeust];
    
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    self.session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue currentQueue]];
    
    //判断是否缓存
    NSString *name = [NSString stringWithFormat:@"%@.jpg", self.request.URL.absoluteString];
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:name];
    if([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        mutableReqeust.URL = [NSURL fileURLWithPath:path];
    }
    [[self.session dataTaskWithRequest:mutableReqeust] resume];
}

- (void)stopLoading
{
    [self.session invalidateAndCancel];
}

#pragma mark dataDelegate
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    
    if (completionHandler) {
        completionHandler(NSURLSessionResponseAllow);
    }
    
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data{
    NSData *transData = data;
    NSString *extension = [dataTask.currentRequest.URL pathExtension];
    if ([extension caseInsensitiveCompare:@"webp"] == NSOrderedSame) {
        UIImage *imgData = [UIImage sd_imageWithWebPData:data];
        transData = UIImageJPEGRepresentation(imgData, 1.0f);
        //写入缓存
        NSString *name = [NSString stringWithFormat:@"%@.jpg", dataTask.currentRequest.URL.absoluteString];
        NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:name];
        if (transData != nil) {
            BOOL yy = [transData writeToFile:path atomically:YES];
            if (yy) {
                NSLog(@"写入成功");
            }
        }
    }
    [self.client URLProtocol:self didLoadData:transData];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error{
    
    if (error) {
        
        [self.client URLProtocol:self didFailWithError:error];
    }else{
        
        [self.client URLProtocolDidFinishLoading:self];
    }
    
}

@end
