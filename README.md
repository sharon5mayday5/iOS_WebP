# iOS_WebP


1. 页面加载webp格式图片


  #ifdef SD_WEBP
  
      [wpimage setImage:[UIImage sd_imageWithWebPData:data]];
      
  #endif
  
  
 2.webview加载webp格式图片
 
 
 第一种方法：和JS协作
 
  - (void)webViewDidFinishLoad:(UIWebView *)webView{
 
     //--------------------------------JS协作的测试------
    
  }
  
 
第二种方法：自定义NSURLProtocal

   //注册协议
   
   [NSURLProtocol registerClass:[CYCustomURLProtocal class]];
   
   
详细解释请参考：http://www.jianshu.com/p/478d680322bf
    
  
