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


#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"


@interface ViewController () <GLKViewDelegate>

@property (nonatomic,strong) EAGLContext *mainContext;

@property (nonatomic , assign) int indicesCount;

@property (nonatomic , strong) GLKBaseEffect* baseEffect;

/* Method Two */
@property (nonatomic,strong) CAEAGLLayer *eaglLayer;

@property (nonatomic,assign) GLuint colorRenderBuffer;
@property (nonatomic,assign) GLuint frameBuffer;

@property (nonatomic,assign) GLint width;
@property (nonatomic,assign) GLint height;


/* 绘制 `点` */
@property (nonatomic,assign)GLuint programHandle;



@end

#define UseGLKitMethod YES // NO

@implementation ViewController
{
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    
    [self createOpenGLContext];
    if (UseGLKitMethod == YES) {
        [self createGLKView];
        
    }else{
        
    }
    
    
    // 配置顶点着色器和片段着色器进行颜色设置
    // 此方法只是进行颜色的着色，如果不调用也并不会影响我们的程序和图形的正确创建和生成。
    [self compileShadersCreatProgram];
    // 绘制`矩形`
    [self createGraphics];
    
    // 绘制`点`
    //[self createDrawPoints];
    
    
}




#pragma mark -  `GLKitView` --- set up OpenGL ES
// step 1
- (void)createOpenGLContext{
    /* context */
    _mainContext = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES2];
    //设置当前屏幕view显示上下文为初始化的 self.mainContext
    if (!_mainContext) {
        NSLog(@"Failed to initialize OpenGLES 2.0 context");
        exit(1);
    }
    // 设置为当前上下文
    if (![EAGLContext setCurrentContext:_mainContext]) {
        NSLog(@"Failed to set current OpenGL context");
        exit(1);
    }
    
}
// M1 - step 2 -- create GLKView
- (void)createGLKView{
    
    GLKView *glkV = [[GLKView alloc]initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    [self.view addSubview:glkV];
    glkV.delegate = self; // you must set delegate, to clear screen color and setDrawElement.
    glkV.context = _mainContext;
    glkV.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;  // 颜色缓冲区格式
}

// M2 - step 2 -- set up CAEAGLLayer
- (void)setupCAEAGLLayer:(CGRect)rect {
    _eaglLayer = [CAEAGLLayer layer];
    _eaglLayer.frame = rect;
    _eaglLayer.backgroundColor = [UIColor yellowColor].CGColor;
    _eaglLayer.opaque = YES;
    
    _eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO],kEAGLDrawablePropertyRetainedBacking,kEAGLColorFormatRGBA8,kEAGLDrawablePropertyColorFormat, nil];
    [self.view.layer addSublayer:_eaglLayer];
}

// M2 - step 3
- (void)clearRenderBuffers {
    if(_colorRenderBuffer){
        glDeleteRenderbuffers(1, &_colorRenderBuffer);
        _colorRenderBuffer = 0;
    }
    
    if(_frameBuffer){
        glDeleteFramebuffers(1, &_frameBuffer);
        _frameBuffer = 0;
    }
    
}


// M2 - step 4
- (void)setupRenderBuffers{
    glGenFramebuffers(1, &_frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    
    glGenRenderbuffers(1, &_colorRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
    
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderBuffer);
    [_mainContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];
    
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &width);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &height);
    //check success
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"Failed to make complete framebuffer object: %i", glCheckFramebufferStatus(GL_FRAMEBUFFER));
    }
    
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


- (void)createDrawPoints{
    static GLfloat points[] = { // 前三位表示位置x, y, z 后三位表示颜色值r, g, b
        0.0f, 0.5f, 0,  0, 0, 0, // 位置为( 0.0, 0.5, 0.0); 颜色为(0, 0, 0)黑色
        -0.5f, 0.0f, 0,     1, 0, 0, // 位置为(-0.5, 0.0, 0.0); 颜色为(1, 0, 0)红色
        0.5f, 0.0f, 0,  1, 0, 0  // 位置为( 0.5, 0.0, 0.0); 颜色为(1, 0, 0)红色
    }; // 共有三组数据，表示三个点
    
    GLuint attrib_position = glGetAttribLocation(_programHandle, "vertexShaderPosition");
    glEnableVertexAttribArray(attrib_position);
    GLuint attrib_color    = glGetAttribLocation(_programHandle, "fragColor");
    glEnableVertexAttribArray(attrib_color);
    
    // 对于position每个数值包含3个分量，即3个byte，两组数据间间隔6个GLfloat
    // 同样,对于color每个数值含3个分量，但数据开始的指针位置为跳过3个position的GLFloat大小
    glVertexAttribPointer(attrib_position, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(GLfloat), (char *)points);
   glVertexAttribPointer(attrib_color, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(GLfloat), (char *)points + 3 * sizeof(GLfloat));
    
    glDrawArrays(GL_POINTS, 0, 3);
    
}


#pragma mark - create `program` object
- (void)compileShadersCreatProgram{
    // generate vertex shader
    GLuint vertexShader = [self compileShaderWithName:@"GraphicVertex" shaderType:GL_VERTEX_SHADER];
    
    // generate fragment shader
    GLuint fragmentShader = [self compileShaderWithName:@"GraphicFragment" shaderType:GL_FRAGMENT_SHADER];

    
    // ....
    _programHandle = glCreateProgram(); //
    glAttachShader(_programHandle, vertexShader); // link vertex shader
    glAttachShader(_programHandle, fragmentShader); // link fragment shader
    glLinkProgram(_programHandle); // link program
    
    // after shader object link program,delete shader object
    //glDeleteShader(vertexShader);
    //glDeleteShader(fragmentShader);
    
    // use `glGetProgramiv` to test error or not
    GLint linkSuccess;
    glGetProgramiv(_programHandle, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar messages[256];
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"shader program:%@", messageString);
        exit(1);
    }
    
    // use `glUseProgram` bind program object,let `OpenGL ES` execute program to rendering.
    glUseProgram(_programHandle);
    
    // 把“顶点属性索引”绑定到“顶点属性名” --> program object -->GraphicVertex.glsl/vertexShaderPosition
    glGetAttribLocation(_programHandle, "vertexShaderPosition");
    glGetAttribLocation(_programHandle, "fragColor");
    
}


//  package create `shader` object
- (GLuint)compileShaderWithName:(NSString *)shaderName shaderType:(GLenum)shaderType{
    // *** this 'glsl' file can't exist Chinese ***
    NSString *shaderPath = [[NSBundle mainBundle]pathForResource:shaderName ofType:@"glsl"];
    // read shader string origin code
    NSError *error;
    NSString *shaderStr = [NSString stringWithContentsOfFile:shaderPath encoding:NSUTF8StringEncoding error:&error];
    
    
    if((shaderStr.length == 0) || !shaderStr){
        NSLog(@"着色器出错：%@",error.localizedDescription);
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
    //r,g,b -- 76.5, 153, 255
    // glClearColor(0.3f, 0.6f, 1.0f, 1.0f);
    
    glClearColor(1.0f,1.0f,1.0f, 1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    //启动着色器
    glDrawElements(GL_TRIANGLES, self.indicesCount, GL_UNSIGNED_INT, 0);
}


#pragma mark - method 2
- (void)useMethodTwo{
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
     [self.mainContext presentRenderbuffer:GL_RENDERBUFFER];
    
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








@end
