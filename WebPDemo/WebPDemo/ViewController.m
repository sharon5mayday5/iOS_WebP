//
//  ViewController.m
//  WebPDemo
//
//  Created by songshan on 2017/8/7.
//  Copyright © 2017年 songshan. All rights reserved.
//

#import "ViewController.h"
#import "WebpTestViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self createBtn];
}

- (void)createBtn{
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(100, 100, 200, 150);
    btn.backgroundColor = [UIColor cyanColor];
    [btn setTitle:@"测试" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(gotoWebpTestVC) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
}

- (void)gotoWebpTestVC{
    WebpTestViewController *test = [[WebpTestViewController alloc] init];
    [self.navigationController pushViewController:test animated:YES];
}
@end
