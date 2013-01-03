//
//  GSGreenScreenEffect.m
//  GreenScreen
//
/*
Copyright (c) 2012 Erik M. Buck

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#import "GSGreenScreenEffect.h"

/////////////////////////////////////////////////////////////////
// GLSL program uniform indices.
enum
{
   GSamplers2D,
   GMVPMatrix,
   GNumUniforms
};


@interface GSGreenScreenEffect ()
{
   GLint uniforms[GNumUniforms];
   GLKBaseEffect *foo;
}

@end



@implementation GSGreenScreenEffect

@synthesize texture2d0 = texture2d0_;
@synthesize transform = transform_;

/////////////////////////////////////////////////////////////////
// Subclasses should override this implementation to load any
// OpenGL ES 2.0 Shading Language programs prior to drawing any 
// geometry with the receiver. The override should typically
// call [self loadShadersWithName:<baseName>] specifying the
// base name for the desired Shading Language programs.
- (void)prepareOpenGL
{
   texture2d0_ = [[GLKEffectPropertyTexture alloc] init];
   transform_ = [[GLKEffectPropertyTransform alloc] init];
   [self loadShadersWithName:@"greenScreen"];
}


/////////////////////////////////////////////////////////////////
// Binds any OpenGL ES 2.0 Shading Language program attributes.
- (void)bindAttribLocations;
{
   glBindAttribLocation(
      self.program, 
      UtilityVertexAttribPosition, 
      "aPosition");
   glBindAttribLocation(
      self.program, 
      UtilityVertexAttribTexCoord0, 
      "aTextureCoordinate");
}


/////////////////////////////////////////////////////////////////
// Subclasses should override this implementation to configure 
// OpenGL uniform values prior to drawing any geometry with the
// receiver.
- (void)updateUniformValues
{
   // Precalculate the mvpMatrix
   GLKMatrix4 modelViewProjectionMatrix = GLKMatrix4Multiply(
      self.transform.projectionMatrix, 
      self.transform.modelviewMatrix);
   glUniformMatrix4fv(uniforms[GMVPMatrix], 1, 0, 
      modelViewProjectionMatrix.m);
      
   // Texture samplers
   const GLint   samplerIDs[1] = {self.texture2d0.name};
   glUniform1iv(uniforms[GSamplers2D], 1, 
      samplerIDs); 
}


/////////////////////////////////////////////////////////////////
// 
- (void)configureUniformLocations;
{
   uniforms[GMVPMatrix] = glGetUniformLocation(
      self.program, 
      "uMVPMatrix");
   uniforms[GSamplers2D] = glGetUniformLocation(
      self.program, 
      "uVideoframe");
}

@end
