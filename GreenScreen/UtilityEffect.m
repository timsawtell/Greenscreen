//
//  UtilityEffect.m
//  
//
/*
Copyright (c) 2012 Erik M. Buck

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#import "UtilityEffect.h"


@interface UtilityEffect ()

@property (assign, nonatomic, readwrite) GLuint program;

- (BOOL)compileShader:(GLuint *)shader 
   type:(GLenum)type 
   file:(NSString *)file;
- (BOOL)linkProgram:(GLuint)prog;
- (BOOL)validateProgram:(GLuint)prog;

@end


@implementation UtilityEffect

@synthesize program = program_;

/////////////////////////////////////////////////////////////////
// Destroy OpenGl state used by the receiver 
- (void)dealloc
{
   if(0 != program_)
   {
      glUseProgram(0);
      glDeleteProgram(program_);
   }
}


#pragma mark -  Rendering

/////////////////////////////////////////////////////////////////
// Subclasses should override this implementation to load any
// OpenGL ES 2.0 Shading Language programs prior to drawing any 
// geometry with the receiver. The override should typically
// call [self loadShadersWithName:<baseName>] specifying the
// base name for the desired Shading Language programs.
- (void)prepareOpenGL
{
}


/////////////////////////////////////////////////////////////////
// Subclasses should override this implementation to configure 
// OpenGL uniform values prior to drawing any geometry with the
// receiver.
- (void)updateUniformValues
{
}


/////////////////////////////////////////////////////////////////
// If the receiver's OpenGL ES 2.0 Shading Language programs have
// not been loaded, this method calls -prepareOpenGL. This method
// configures the OpenGL state to use the receiver's OpenGL ES 
// 2.0 Shading Language programs and then calls 
// -updateUniformValues to update any Shading Language program
// specific state required for drawing.
- (void)prepareToDraw;
{
   if(0 == self.program)
   {
      [self prepareOpenGL];
      
      NSAssert(0 != self.program,
         @"prepareOpenGL failed to load shaders");
   }
   
   glUseProgram(self.program);
   
   [self updateUniformValues];
}

#pragma mark -  OpenGL ES 2 shader compilation overloads

/////////////////////////////////////////////////////////////////
// Subclasses must override this implementation to bind any 
// OpenGL ES 2.0 Shading Language program attributes.
- (void)bindAttribLocations;
{
   NSAssert(0, 
      @"Subclasses failed to override this implementation");
}


/////////////////////////////////////////////////////////////////
// Subclasses must override this implementation to bind any 
// OpenGL ES 2.0 Shading Language program uniform locations.
- (void)configureUniformLocations;
{
   NSAssert(0, 
      @"Subclasses failed to override this implementation");
}


#pragma mark -  OpenGL ES 2 shader compilation

/////////////////////////////////////////////////////////////////
// This method loads and compiles OpenGL ES 2.0 Shading Language 
// programs with the root name aShaderName and the 
// suffixes/extensions "vsh" and "fsh".
- (BOOL)loadShadersWithName:(NSString *)aShaderName;
{
   NSParameterAssert(nil != aShaderName);
   
   GLuint vertShader, fragShader;
   NSString *vertShaderPathname, *fragShaderPathname;
   
   // Create shader program.
   self.program = glCreateProgram();
   
   // Create and compile vertex shader.
   vertShaderPathname = [[NSBundle mainBundle] 
      pathForResource:aShaderName ofType:@"vsh"];
   if (![self compileShader:&vertShader type:GL_VERTEX_SHADER 
      file:vertShaderPathname]) 
   {
      NSLog(@"Failed to compile vertex shader");
      return NO;
   }
   
   // Create and compile fragment shader.
   fragShaderPathname = [[NSBundle mainBundle] 
      pathForResource:aShaderName ofType:@"fsh"];
   if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER 
      file:fragShaderPathname]) 
   {
      NSLog(@"Failed to compile fragment shader");
      return NO;
   }
   
   // Attach vertex shader to program.
   glAttachShader(self.program, vertShader);
   
   // Attach fragment shader to program.
   glAttachShader(self.program, fragShader);
   
   // Bind attribute locations.
   // This needs to be done prior to linking.
   [self bindAttribLocations];
   
   // Link program.
   if (![self linkProgram:self.program]) 
   {
      NSLog(@"Failed to link program: %d", self.program);
      
      if (vertShader) 
      {
         glDeleteShader(vertShader);
         vertShader = 0;
      }
      if (fragShader) 
      {
         glDeleteShader(fragShader);
         fragShader = 0;
      }
      if (self.program) 
      {
         glDeleteProgram(self.program);
         self.program = 0;
      }
      
      return NO;
   }

   // Get uniform locations.
   [self configureUniformLocations];
   
   // Delete vertex and fragment shaders.
   if (vertShader) 
   {
      glDetachShader(self.program, vertShader);
      glDeleteShader(vertShader);
   }
   if (fragShader) 
   {
      glDetachShader(self.program, fragShader);
      glDeleteShader(fragShader);
   }
   
   return YES;
}


/////////////////////////////////////////////////////////////////
// 
- (BOOL)compileShader:(GLuint *)shader 
   type:(GLenum)type 
   file:(NSString *)file
{
   GLint status;
   const GLchar *source;
   
   source = (GLchar *)[[NSString stringWithContentsOfFile:file 
      encoding:NSUTF8StringEncoding error:nil] UTF8String];
   if (!source) 
   {
      NSLog(@"Failed to load vertex shader");
      return NO;
   }
   
   *shader = glCreateShader(type);
   glShaderSource(*shader, 1, &source, NULL);
   glCompileShader(*shader);
   
#if defined(DEBUG)
   GLint logLength;
   glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
   if (logLength > 0) 
   {
      GLchar *log = (GLchar *)malloc(logLength);
      glGetShaderInfoLog(*shader, logLength, &logLength, log);
      NSLog(@"Shader compile log:\n%s", log);
      free(log);
   }
#endif
   
   glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
   if (status == 0) 
   {
      glDeleteShader(*shader);
      return NO;
   }
   
   return YES;
}


/////////////////////////////////////////////////////////////////
// 
- (BOOL)linkProgram:(GLuint)prog
{
   GLint status;
   glLinkProgram(prog);
   
#if defined(DEBUG)
   GLint logLength;
   glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
   if (logLength > 0) 
   {
      GLchar *log = (GLchar *)malloc(logLength);
      glGetProgramInfoLog(prog, logLength, &logLength, log);
      NSLog(@"Program link log:\n%s", log);
      free(log);
   }
#endif
   
   glGetProgramiv(prog, GL_LINK_STATUS, &status);
   if (status == 0) 
   {
      return NO;
   }
   
   return YES;
}


/////////////////////////////////////////////////////////////////
// 
- (BOOL)validateProgram:(GLuint)prog
{
   GLint logLength, status;
   
   glValidateProgram(prog);
   glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
   if (logLength > 0) 
   {
      GLchar *log = (GLchar *)malloc(logLength);
      glGetProgramInfoLog(prog, logLength, &logLength, log);
      NSLog(@"Program validate log:\n%s", log);
      free(log);
   }
   
   glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
   if (status == 0) 
   {
      return NO;
   }
   
   return YES;
}

@end
