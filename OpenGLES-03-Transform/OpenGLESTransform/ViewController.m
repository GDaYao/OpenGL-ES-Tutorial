//
//  ViewController.m
//  OpenGLESTransform
//
//  Created by Dayao on 2018/10/8.
//  Copyright © 2018年 Dayao. All rights reserved.
//

#import "ViewController.h"
#import "TransformCustomView.h"


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
 
    TransformCustomView *customV = [[TransformCustomView alloc]initWithFrame:self.view.frame];
    [self.view addSubview:customV];
    
}




@end
