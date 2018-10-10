//
//  ViewController.m
//  OpenGL ES Graphics
//
//  Created by Dayao on 2018/9/29.
//  Copyright © 2018年 Dayao. All rights reserved.
//


#import "ViewController.h"

// <file/file.h>
#import <GLKit/GLKit.h>
#import <CoreImage/CoreImage.h>

@interface ViewController () <GLKViewDelegate>

@property (nonatomic,strong)EAGLContext *mainContext;

@property (nonatomic , assign)int indicesCount;

@property (nonatomic , strong) GLKBaseEffect* baseEffect;

@end

@implementation ViewController
{
    /* other way
     CAEAGLLayer _eaglLayer;
     GLuint _colorRenderBuffer; // 渲染缓冲区
     GLuint _frameBuffer; // 帧缓冲区
     */
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self createOpenGLContext];
    
    
    [self createGraphics];
    
    // 配置顶点着色器和片段着色器进行颜色设置
    // 此方法只是进行颜色的着色，如果不调用也并不会影响我们的程序和图形的正确创建和生成。
    [self compileShadersCreatProgram];
    
}


#pragma mark - 创建 OpenGL ES 上下文
- (void)createOpenGLContext{
    /* context */
    self.mainContext = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [EAGLContext setCurrentContext:self.mainContext]; //设置当前屏幕view显示上下文为初始化的 self.mainContext
    
    GLKView *glkV = [[GLKView alloc]initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    [self.view addSubview:glkV];
    glkV.delegate = self; // you must set delegate, to clear screen color and setDrawElement.
    glkV.context = self.mainContext;
    glkV.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;  // 颜色缓冲区格式
    
}


#pragma mark - create graphics
/*  图形绘制
 *  三角形，矩形(OpenGL 主要绘制三角形)
 // OpenGL 绘制步骤
 // 1. 使用一个顶点缓冲对象将顶点数据初始化至缓冲区中
 // 2. 建立了一个顶点和一个片段着色器程序对象
 // 3. 告诉OpenGL如何把顶点数据链接到顶点着色器的顶点属性上
 // 4. 最后只需要调用绘制函数 glDrawArrays 进行绘制
 */
- (void)createGraphics{
    // OpenGLES的原点 (0,0) 在屏幕中间
    //顶点数组数据，前三个是顶点坐标（x、y、z轴），后面两个是纹理坐标（x，y）
    // VB)
    GLfloat squareVertexData[] = {
        -0.5, 0.5, 0.0f,    0.0f, 1.0f, //左上
        -0.5, -0.5, 0.0f,   0.0f, 0.0f, //左下
        0.5, 0.5, -0.0f,    1.0f, 1.0f, //右上
        0.5, -0.5, 0.0f,    1.0f, 0.0f, //右下
    };
    
    // 索引缓冲对象 -- EBO
    GLuint indices[] =
    {
        0,1,3,
        0,3,2
    };
    self.indicesCount = sizeof(indices) / sizeof(GLuint);
    
    // 顶点数据缓存
    // 顶点数组 -- buffer
    GLuint buffer;
    // 申请一个标识符
    glGenBuffers(1, &buffer);
    // 绑定标识符到 'GL_ARRAY_BUFFER'
    glBindBuffer(GL_ARRAY_BUFFER, buffer);
    // 用户定义的数据复制到当前绑定缓冲的函数
    glBufferData(GL_ARRAY_BUFFER, sizeof(squareVertexData), squareVertexData, GL_STATIC_DRAW);
    
    // 顶点索引 -- index
    GLuint index;
    glGenBuffers(1, &index);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, index);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);
    
    
    // 开启对应顶点属性
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    // 设置合适的格式从buffer里面读取数据 -- 设置的顶点属性配置,调用与顶点属性关联的顶点缓冲对象
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *)NULL + 0);
    
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0); // 纹理
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *)NULL + 3);
    
    /*
     参数说明：
     第一个参数GLenum mode：绘制方式,这里是绘制三角形，所以选择GL_TRIANGLES
     第二个参数GLint first：从数组缓存中的哪一位开始绘制，一般为0。
     第三个参数GLsizei cout：数组中顶点数据的数量。
     */
    //glDrawArrays(GL_TRIANGLES, 0, 6);
    
    // 在使用 索引缓冲对象绘制时，替换使用 `glDrawArrays`--> glDrawElements
    /*参数说明:
     第一个参数GLenum mode：与glDrawArrays函数的第一个参数一样，指定绘制方式,这里是绘制三角形，所以选择GL_TRIANGLES
     第二个参数GLsizei cout：绘制顶点的个数
     第三个参数GLenum type：为索引数组(indices)中元素的类型，只能是下列值之一
     GL_UNSIGNED_BYTE,
     GL_UNSIGNED_SHORT,
     GL_UNSIGNED_INT
     第四个参数const GLvoid *indices：指向索引存贮位置的指针
     */
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0); // GL_UNSIGNED_BYTE
    
}


#pragma mark - create `program` object
- (void)compileShadersCreatProgram{
    // generate vertex shader
    GLuint vertexShader = [self compileShaderWithName:@"GraphicVertex" shaderType:GL_VERTEX_SHADER];
    //GLuint vertexShader = [self compileShaderWithName:@"SimpleVertex" shaderType:GL_VERTEX_SHADER];
    
    // generate fragment shader
    GLuint fragmentShader = [self compileShaderWithName:@"GraphicFragment" shaderType:GL_FRAGMENT_SHADER];
    //GLuint fragmentShader = [self compileShaderWithName:@"SimpleFragment" shaderType:GL_FRAGMENT_SHADER];
    
    // ....
    GLuint programHandle = glCreateProgram(); //
    glAttachShader(programHandle, vertexShader); // link vertex shader
    glAttachShader(programHandle, fragmentShader); // link fragment shader
    glLinkProgram(programHandle); // link program
    
    // after shader object link program,delete shader object
    //glDeleteShader(vertexShader);
    //glDeleteShader(fragmentShader);
    
    // use `glGetProgramiv` to test error or not
    GLint linkSuccess;
    glGetProgramiv(programHandle, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar messages[256];
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"shader program:%@", messageString);
        exit(1);
    }
    
    // use `glUseProgram` bind program object,let `OpenGL ES` execute program to rendering.
    glUseProgram(programHandle);
    
    // 把“顶点属性索引”绑定到“顶点属性名” --> program object -->GraphicVertex.glsl/vertexShaderPosition
    glGetAttribLocation(programHandle, "vertexShaderPosition");
}

//  package create `shader` object
- (GLuint)compileShaderWithName:(NSString *)shaderName shaderType:(GLenum)shaderType{
    // *** this 'glsl' file can't exist Chinese ***
    NSString *shaderPath = [[NSBundle mainBundle]pathForResource:shaderName ofType:@"glsl"];
    // read shader string origin code
    NSError *error;
    NSString *shaderStr = [NSString stringWithContentsOfFile:shaderPath encoding:NSUTF8StringEncoding error:&error];
    
    
    if((shaderStr.length == 0) || !shaderStr){
        exit(1);
    }
    
    // create shader object
    GLuint shader;
    shader = glCreateShader(shaderType);
    
    // use `glShaderSource` 将着色器源码加载到上面生成的着色器对象上
    const char* shaderStrUTF8 = [shaderStr UTF8String];
    int shaderStrLength = (int)shaderStr.length;
    glShaderSource(shader, 1, &shaderStrUTF8, &shaderStrLength);
    
    // 调用glCompileShader 在运行时编译shader
    glCompileShader(shader);
    
    // glGetShaderiv检查编译错误（然后退出）
    GLint compileSuccess;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &compileSuccess);
    if (compileSuccess == GL_FALSE) {
        GLchar messages[256];
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        exit(1);
    }
    return shader;
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
    //r,g,b -- 76.5,153,255
    //glClearColor(0.3f, 0.6f, 1.0f, 1.0f);
    
    glClearColor(1.0f,1.0f,1.0f, 1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    //启动着色器
    glDrawElements(GL_TRIANGLES, self.indicesCount, GL_UNSIGNED_INT, 0);
    
    // from UIImage to screen in image
    // [self.baseEffect prepareToDraw];
    
}



/* other way
 - (void)otherOperate{
 // setupCAEAGLLayer
 self.eaglLayer = [CAEAGLLayer layer];
 self.eaglLayer.frame = self.view.frame;
 self.eaglLayer.opaque = YES; // 默认透明
 
 self.eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO],kEAGLDrawablePropertyRetainedBacking,kEAGLColorFormatRGBA8,kEAGLDrawablePropertyColorFormat, nil];
 [self.view.layer addSublayer:self.eaglLayer];
 
 [self destoryBuffer];
 
 [self setupRenderAndFrameBuffer];
 
 // 设置清屏颜色
 glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
 // 用来指定要用清屏颜色来清除由mask指定的buffer，此处是color buffer
 glClear(GL_COLOR_BUFFER_BIT);
 
 glViewport(0, 0, self.view.frame.size.width, self.view.frame.size.height);
 
 
 // in all operate end.
 // [self.mainContext presentRenderbuffer:GL_RENDERBUFFER];
 
 }
 - (void)destoryBuffer{
 // 销毁渲染区和帧缓冲区
 if (_colorRenderBuffer) {
 glDeleteRenderbuffers(1, &_colorRenderBuffer);
 _colorRenderBuffer = 0;
 }
 
 if (_frameBuffer) {
 glDeleteFramebuffers(1, &_frameBuffer);
 _frameBuffer = 0;
 }
 }
 - (void)setupRenderAndFrameBuffer{
 
 //先要renderbuffer，然后framebuffer，顺序不能互换。
 
 glGenRenderbuffers(1, &_colorRenderBuffer);
 // 设置为当前renderBuffer
 glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
 //为color renderbuffer 分配存储空间
 [self.mainContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.eaglLayer];
 
 // FBO用于管理colorRenderBuffer，离屏渲染
 glGenFramebuffers(1, &_frameBuffer);
 //设置为当前framebuffer
 glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
 // 将 _colorRenderBuffer 装配到 GL_COLOR_ATTACHMENT0 这个装配点上
 glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderBuffer);
 }
 */




@end
