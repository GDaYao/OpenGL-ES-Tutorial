//
//  ViewController.m
//  GLPaint
//
//  Created by Dayao on 2018/10/10.
//  Copyright © 2018年 Dayao. All rights reserved.
//

#import "PaintViewController.h"
#import "PaintView.h"


#define kScreenBounds [[UIScreen mainScreen] bounds]


#define kLeftMargin 10.0
#define kRightMargin 10.0
#define kBottomMargin 10.0
#define kPaletteHeight 40.0

#define kPaletteSize 5.0
#define kSaturation 0.5
#define kBrightness 1.0


@interface PaintViewController ()

@end

@implementation PaintViewController

#pragma mark - view life

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor blackColor];
    
    
    [self createPaintUI];
    
    
}

- (void)createPaintUI{
    UISegmentedControl *colorSC = [[UISegmentedControl alloc]initWithItems:
                                   [NSArray arrayWithObjects:
                                    [[UIImage imageNamed:@"red"]
                                        imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal],
                                    [[UIImage imageNamed:@"yellow"]
                                        imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal],
                                    [[UIImage imageNamed:@"green"]
                                        imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal],
                                    [[UIImage imageNamed:@"blue"]
                                        imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal],
                                    [[UIImage imageNamed:@"purple"]
                                        imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal],
                                    nil]];
    colorSC.frame = CGRectMake(kLeftMargin, kScreenBounds.size.height-kPaletteHeight-kBottomMargin, kScreenBounds.size.width-kLeftMargin-kRightMargin, kPaletteHeight);
    colorSC.selectedSegmentIndex = 2;
    colorSC.tintColor = [UIColor darkGrayColor];
    [self.view addSubview:colorSC];
    [colorSC addTarget:self action:@selector(changeBrushColor:) forControlEvents:UIControlEventValueChanged];
    
    
    
    // Define a starting color
    CGColorRef color = [UIColor colorWithHue:(CGFloat)2.0 / (CGFloat)kPaletteSize
                                  saturation:kSaturation
                                  brightness:kBrightness
                                       alpha:1.0].CGColor;
    const CGFloat *components = CGColorGetComponents(color);
    
    // Defer to the OpenGL view to set the brush color
    [(PaintView *)self.view setBrushColorWithRed:components[0] green:components[1] blue:components[2]];
    
    
    
    // Load the sounds
//    NSBundle *mainBundle = [NSBundle mainBundle];
//    erasingSound = [[SoundEffect alloc] initWithContentsOfFile:[mainBundle pathForResource:@"Erase" ofType:@"caf"]];
//    selectSound =  [[SoundEffect alloc] initWithContentsOfFile:[mainBundle pathForResource:@"Select" ofType:@"caf"]];
    
    // Erase the view when recieving a notification named "shake" from the NSNotificationCenter object
    // The "shake" nofification is posted by the PaintingWindow object when user shakes the device
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(eraseView) name:@"shake" object:nil];
    
    
}



#pragma mark - target

- (void)changeBrushColor:(id)value{
    
    
}









@end
