//
//  TransformCustomView.m
//  OpenGLESTransform
//  Copyright © 2018年 Dayao. All rights reserved.
//

#import "TransformCustomView.h"
#import <OpenGLES/ES2/gl.h>

@interface TransformCustomView()

@property (nonatomic,strong)EAGLContext* mainContext;
@property (nonatomic,strong)CAEAGLLayer* mainEAGLLayer;

@property (nonatomic,assign)GLuint mainProgram;

@property (nonatomic,assign)GLuint mainColorRenderBuffer;
@property (nonatomic,assign)GLuint mainColorFrameBuffer;

@end



@implementation TransformCustomView

#pragma mark - super init
- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if(self){
        [self createVetexTextureTransform];
    }
    return self;
}

#pragma mark - **layer class**
+ (Class)layerClass {
    /*
     重写UIView类的class声明为 CAEAGLLayer class.
     */
    return [CAEAGLLayer class];
}

#pragma mark - create vertex texture transform
- (void)createVetexTextureTransform{
    [self setContextAndLayer];
    
    [self destoryRenderAndFrameBuffer];
    [self setupRenderAndFrameBuffer];
    
    [self mainRender];
    
}

#pragma mark - context-layer
- (void)setContextAndLayer{
// set up layer
    self.mainEAGLLayer = (CAEAGLLayer *)self.layer;
    // 1. 设置放大倍数
    [self setContentScaleFactor:[[UIScreen mainScreen]scale]];
    
    // CALayer 默认是透明的，必须将它设为不透明才能让其可见
    self.mainEAGLLayer.opaque = YES;
    
    // 设置描绘属性，在这里设置不维持渲染内容以及颜色格式为 RGBA8
    self.mainEAGLLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                          [NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
// set up context
    self.mainContext = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [EAGLContext setCurrentContext:self.mainContext];
    
}
#pragma mark - destory render and frame buffer
- (void)destoryRenderAndFrameBuffer{
    glDeleteFramebuffers(1, &_mainColorFrameBuffer);
    self.mainColorFrameBuffer = 0;
    glDeleteRenderbuffers(1, &_mainColorRenderBuffer);
    self.mainColorRenderBuffer = 0;
}

#pragma mark - set render and frame buffer
- (void)setupRenderAndFrameBuffer{
    GLuint renderBuffer;
    glGenRenderbuffers(1, &renderBuffer);
    self.mainColorRenderBuffer = renderBuffer;
    glBindRenderbuffer(GL_RENDERBUFFER, self.mainColorRenderBuffer);
    // 为 颜色缓冲区 分配存储空间
    [self.mainContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.mainEAGLLayer];
    
    
    GLuint frameBuffer;
    glGenFramebuffers(1, &frameBuffer);
    self.mainColorFrameBuffer = frameBuffer;
    // 设置为当前 framebuffer
    glBindFramebuffer(GL_FRAMEBUFFER, self.mainColorFrameBuffer);
    // 将 _colorRenderBuffer 装配到 GL_COLOR_ATTACHMENT0 这个装配点上
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                              GL_RENDERBUFFER, self.mainColorFrameBuffer);
}


#pragma mark - main render
- (void)mainRender{
    
// usually set
    glClearColor(70/255.0, 130/255.0, 180/255.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    CGFloat scale = [[UIScreen mainScreen]scale]; //获取视图放大倍数
    glViewport(self.frame.origin.x * scale, self.frame.origin.y * scale, self.frame.size.width * scale, self.frame.size.height * scale); // 设置可见view视图大小
    
// read string file
    NSString *vertFile = [[NSBundle mainBundle]pathForResource:@"shaderv" ofType:@"vsh"];
    NSString *fragFile = [[NSBundle mainBundle]pathForResource:@"shaderf" ofType:@"fsh"];
    
// 加载shader
    self.mainProgram = [self loadShader:vertFile withFrag:fragFile];
    
// 链接
    glLinkProgram(self.mainProgram);
    GLint linkSuccess;
    glGetProgramiv(self.mainProgram, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {  //连接错误
        GLchar messages[256];
        glGetProgramInfoLog(self.mainProgram, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"error%@", messageString);
        return ;
    }
    else {
        NSLog(@"link ok");
        glUseProgram(self.mainProgram);
    }
    
// create vert array
    GLfloat attrArr[] =
    {
        0.5f, -0.5f, -1.0f,     1.0f, 0.0f,
        -0.5f, 0.5f, -1.0f,     0.0f, 1.0f,
        -0.5f, -0.5f, -1.0f,    0.0f, 0.0f,
        0.5f, 0.5f, -1.0f,      1.0f, 1.0f,
        -0.5f, 0.5f, -1.0f,     0.0f, 1.0f,
        0.5f, -0.5f, -1.0f,     1.0f, 0.0f,
    };
    
    GLuint attrBuffer;
    glGenBuffers(1, &attrBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, attrBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_DYNAMIC_DRAW);
    
    GLuint position = glGetAttribLocation(self.mainProgram, "position");
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, NULL);
    glEnableVertexAttribArray(position);
    
    GLuint textCoor = glGetAttribLocation(self.mainProgram, "textCoordinate");
    glVertexAttribPointer(textCoor, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (float *)NULL + 3);
    glEnableVertexAttribArray(textCoor);
    
    
// load UIImage texture
    [self setupTexture:@"Demo3.jpg"];
    
    // 获取shader里面的变量
    GLuint rotate = glGetUniformLocation(self.mainProgram, "rotateMatrix");
    
    float radians = 60 * 3.14159f / 180.0f; // 60
    float s = sin(radians);
    float c = cos(radians);
    
    //z轴旋转矩阵
    GLfloat zRotation[16] = { //
        c, -s, 0, 0.2, //
        s, c, 0, 0,//
        0, 0, 1.0, 0,//
        0.0, 0, 0, 1.0//
    };
    
    //设置旋转矩阵
    glUniformMatrix4fv(rotate, 1, GL_FALSE, (GLfloat *)&zRotation[0]);
    
    glDrawArrays(GL_TRIANGLES, 0, 6);
    
    [self.mainContext presentRenderbuffer:GL_RENDERBUFFER];

}

- (GLuint)loadShader:(NSString *)vert withFrag:(NSString *)frag{
    GLuint vertShader,fragShader;
    GLuint program = glCreateProgram();
    
    // 编译
    [self compileShader:&vertShader type:GL_VERTEX_SHADER file:vert];
    [self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:frag];
    
    
    glAttachShader(program, vertShader);
    glAttachShader(program, fragShader);
    
    glDeleteShader(vertShader);
    glDeleteShader(fragShader);
    
    return program;
}

- (void)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file {
    NSString* content = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil];
    const GLchar* source = (GLchar *)[content UTF8String];
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
}


- (GLuint)setupTexture:(NSString *)fileName {
    // 1获取图片的CGImageRef
    CGImageRef spriteImage = [UIImage imageNamed:fileName].CGImage;
    if (!spriteImage) {
        NSLog(@"Failed to load image %@", fileName);
        exit(1);
    }
    
    // 2 读取图片的大小
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);
    
    GLubyte * spriteData = (GLubyte *) calloc(width * height * 4, sizeof(GLubyte)); //rgba共4个byte
    
    CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width*4,
                                                       CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);
    
    // 3在CGContextRef上绘图
    CGContextDrawImage(spriteContext, CGRectMake(0, 0, width, height), spriteImage);
    
    CGContextRelease(spriteContext);
    
    // 4绑定纹理到默认的纹理ID（这里只有一张图片，故而相当于默认于片元着色器里面的colorMap，如果有多张图不可以这么做）
    glBindTexture(GL_TEXTURE_2D, 0);
    
    
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    float fw = width, fh = height;
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, fw, fh, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
    
    glBindTexture(GL_TEXTURE_2D, 0);
    
    free(spriteData);
    return 0;
}





@end

