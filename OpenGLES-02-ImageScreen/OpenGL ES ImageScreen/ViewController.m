//
//  ViewController.m
//  OpenGL ES ImageScreen
//
//  Created by Dayao on 2018/9/29.
//  Copyright © 2018年 Dayao. All rights reserved.
//


#import "ViewController.h"


// <file/file.h>
#import <GLKit/GLKit.h>
#import <CoreImage/CoreImage.h>

#define isMethodTwo NO // NO

@interface ViewController ()<GLKViewDelegate>

@property (nonatomic,strong)EAGLContext *mainContext;


@property (nonatomic , strong) GLKBaseEffect* baseEffect;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    [self createOpenGLContext];
    
    if (isMethodTwo == YES) {
        /* method 2   -- 纹理贴图 */
        [self createImageWithTextureMapWithImgName:@"flower" withImgType:@"jpg"];
    }else{
        /* method 1  */
        [self createImageFromOriginImageWithImgName:@"flower" withImgType:@"jpg"];
    }
    
    
}

#pragma mark - 创建 OpenGL ES 上下文
- (void)createOpenGLContext{
/* context */
    self.mainContext = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES2];
    //设置当前屏幕view显示上下文为初始化的 self.mainContext
    if (!self.mainContext) {
        NSLog(@"Failed to initialize OpenGLES 2.0 context");
        exit(1);
    }
    // 设置为当前上下文
    if (![EAGLContext setCurrentContext:self.mainContext]) {
        NSLog(@"Failed to set current OpenGL context");
        exit(1);
    }
    
    GLKView *glkV = [[GLKView alloc]initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    [self.view addSubview:glkV];
    glkV.delegate = self; // you must set delegate, to clear screen color and prepareToDraw.
    glkV.context = self.mainContext;
    glkV.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;  // 颜色缓冲区格式
    
}

#pragma mark - 1 - 读取图片信息并绘制屏幕
- (void)createImageFromOriginImageWithImgName:(NSString *)imgName withImgType:(NSString *)imgType{
    // 读取图片生成 TextTure纹理信息
    CVOpenGLESTextureCacheRef coreVideoTextureCache;
    CVPixelBufferRef renderTarget;
    CVOpenGLESTextureRef renderTexture;
    CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, self.mainContext, NULL, &coreVideoTextureCache);
    
    UIImage *screenImg = [UIImage imageNamed:[NSString stringWithFormat:@"%@.%@",imgName,imgType]];
    renderTarget = [self pixelBufferRefFromCGImage:screenImg.CGImage];
    
    CVReturn err = CVOpenGLESTextureCacheCreateTextureFromImage (kCFAllocatorDefault, coreVideoTextureCache, renderTarget,
                                                                 NULL, // texture attributes
                                                                 GL_TEXTURE_2D,
                                                                 GL_RGBA, // opengl format
                                                                 (int)CGImageGetWidth(screenImg.CGImage),
                                                                 (int)CGImageGetHeight(screenImg.CGImage),
                                                                 GL_RGBA, // native iOS format
                                                                 GL_UNSIGNED_BYTE,
                                                                 0,
                                                                 &renderTexture);
    if (err)
    {
        NSAssert(NO, @"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
    }
    
    glBindTexture(CVOpenGLESTextureGetTarget(renderTexture), CVOpenGLESTextureGetName(renderTexture));
    
    // GLKTextureLoader读取图片,创建纹理 CLKTextureInfo
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:@(1),GLKTextureLoaderOriginBottomLeft, nil]; // 纹理坐标系是相反的设置
    NSString *demoFilePath = [[NSBundle mainBundle]pathForResource:imgName ofType:imgType];
    GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithContentsOfFile:demoFilePath options:options error:nil];
    
    
    // 创建着色器 GLKBaseEffect ，把纹理赋值给着色器
    self.baseEffect = [[GLKBaseEffect alloc]init];
    self.baseEffect.texture2d0.enabled = GL_TRUE;
    self.baseEffect.texture2d0.name = CVOpenGLESTextureGetName(renderTarget); //textureInfo.name
    
    
    // 根据生成的原本的图片 textTure 纹理信息在 反向 生成 图片 --> addView
    UIImage *textImg = [self generateImageFromCVPixelBufferRef:renderTarget];
    UIImageView* imageView = [[UIImageView alloc] initWithImage:textImg];
    
    float imgWidth = textImg.size.width;
    float imgHeight = textImg.size.height;
    if ((textImg.size.width> self.view.frame.size.width) || (textImg.size.height>self.view.frame.size.height)) {
        imgWidth = self.view.frame.size.width;
        imgHeight = self.view.frame.size.height;
    }
    
    imageView.frame = CGRectMake((self.view.frame.size.width-imgWidth)/2, (self.view.frame.size.height-imgHeight)/2, imgWidth,imgHeight);
    [self.view addSubview:imageView];
    
}


#pragma mark - 根据 UIImage --> 生成图片纹理相关信息
- (CVPixelBufferRef)pixelBufferRefFromCGImage:(CGImageRef)imgRef{
    NSDictionary *options = @{
                              (NSString*)kCVPixelBufferCGImageCompatibilityKey : @YES,
                              (NSString*)kCVPixelBufferCGBitmapContextCompatibilityKey : @YES,
                              (NSString*)kCVPixelBufferIOSurfacePropertiesKey: [NSDictionary dictionary]
                              };
    CVPixelBufferRef pixelBuffer = NULL;
    
    CGFloat frameWidth = CGImageGetWidth(imgRef);
    CGFloat frameHeight = CGImageGetHeight(imgRef);
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault,
                                          frameWidth,
                                          frameHeight,
                                          kCVPixelFormatType_32BGRA,
                                          (__bridge CFDictionaryRef) options,
                                          &pixelBuffer);
    
    NSParameterAssert(status == kCVReturnSuccess && pixelBuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    void *pixelData = CVPixelBufferGetBaseAddress(pixelBuffer);
    NSParameterAssert(pixelData != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef context = CGBitmapContextCreate(pixelData,
                                                 frameWidth,
                                                 frameHeight,
                                                 8,
                                                 CVPixelBufferGetBytesPerRow(pixelBuffer),
                                                 rgbColorSpace,
                                                 (CGBitmapInfo)kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    CGContextConcatCTM(context, CGAffineTransformIdentity);
    CGContextDrawImage(context, CGRectMake(0,
                                           0,
                                           frameWidth,
                                           frameHeight),
                       imgRef);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    return pixelBuffer;
}


#pragma mark - 图片纹理相关信息 --> generate UIImage
- (UIImage *)generateImageFromCVPixelBufferRef:(CVPixelBufferRef)pixelBufferRef{
    CVImageBufferRef imgBuffer = pixelBufferRef;
    
    CVPixelBufferLockBaseAddress(imgBuffer, 0);
    void *baseAddress = CVPixelBufferGetBaseAddress(imgBuffer);
    size_t width = CVPixelBufferGetWidth(imgBuffer);
    size_t height = CVPixelBufferGetHeight(imgBuffer);
    size_t bufferSize = CVPixelBufferGetDataSize(imgBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(imgBuffer, 0);
    
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, baseAddress, bufferSize, NULL);
    
    CGImageRef cgImage = CGImageCreate(width, height, 8, 32, bytesPerRow, rgbColorSpace, kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrderDefault, provider, NULL, true, kCGRenderingIntentDefault);
    
    UIImage *image = [UIImage imageWithCGImage:cgImage];
    
    CGImageRelease(cgImage);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(rgbColorSpace);
    
    CVPixelBufferUnlockBaseAddress(imgBuffer, 0);
    
    return image;
}

#pragma mark - 2 - vertex generate image texture
- (void)createImageWithTextureMapWithImgName:(NSString *)imgName withImgType:(NSString *)imgType{
    [self uploadVertexArrayMT];
    
    //纹理贴图
    NSString* filePath = [[NSBundle mainBundle] pathForResource:imgName ofType:imgType];
    NSDictionary* options = [NSDictionary dictionaryWithObjectsAndKeys:@(1), GLKTextureLoaderOriginBottomLeft, nil];//GLKTextureLoaderOriginBottomLeft 纹理坐标系是相反的
    GLKTextureInfo* textureInfo = [GLKTextureLoader textureWithContentsOfFile:filePath options:options error:nil];
    //着色器
    self.baseEffect = [[GLKBaseEffect alloc] init];
    self.baseEffect.texture2d0.enabled = GL_TRUE;
    self.baseEffect.texture2d0.name = textureInfo.name;
}

- (void)uploadVertexArrayMT{
    //顶点数据，前三个是顶点坐标（x、y、z轴），后面两个是纹理坐标（x，y）
    GLfloat vertexData[] =
    {
        0.5, -0.5, 0.0f,    1.0f, 0.0f, //右下
        0.5, 0.5, -0.0f,    1.0f, 1.0f, //右上
        -0.5, 0.5, 0.0f,    0.0f, 1.0f, //左上
        
        0.5, -0.5, 0.0f,    1.0f, 0.0f, //右下
        -0.5, 0.5, 0.0f,    0.0f, 1.0f, //左上
        -0.5, -0.5, 0.0f,   0.0f, 0.0f, //左下
    };
    
    //顶点数据缓存
    GLuint buffer;
    glGenBuffers(1, &buffer);
    glBindBuffer(GL_ARRAY_BUFFER, buffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertexData), vertexData, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition); //顶点数据缓存
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *)NULL + 0);
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0); //纹理
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *)NULL + 3);
}



/**
 *  场景数据变化
 */
- (void)update {
    
}

/**
 *  渲染场景代码 -- GLKView independence use -- GLKView delegate
 *  like drawRect:方法相同，用来绘制view的内容的,意思是对delegate的view的进行的重绘
 */
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    // 改变屏幕背景色
    //r,g,b -- 240,230,140
    ///glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
    glClearColor(240/255.0, 230/255.0, 140/255.0, 1.0f);
    
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    // from UIImage to screen in image
    [self.baseEffect prepareToDraw];
    
    if (isMethodTwo == YES) {
        glDrawArrays(GL_TRIANGLES, 0, 6);
    }
    
}






@end
