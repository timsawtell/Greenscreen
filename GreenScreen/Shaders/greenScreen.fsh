//
//  greenScreen.fsh
//  GreenScreen
//
/*
Copyright (c) 2012 Erik M. Buck

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

varying highp vec2 vCoordinate;
uniform sampler2D uVideoframe;
uniform highp mat4 uMVPMatrix;


void main()
{
   // lookup the color of the texel corresponding to the fragment being
   // generated while rendering a triangle
   lowp vec4 tempColor = texture2D(uVideoframe, vCoordinate);
   
   // Calculate the average intensity of the texel's red and blue components
   lowp float rbAverage = tempColor.r * 0.7 + tempColor.b * 0.7;
   
   // Calculate the difference between the green element intensity and the
   // average of red and blue intensities
   lowp float gDelta = tempColor.g - rbAverage;
   
   // If the green intensity is greater than the average of red and blue
   // intensities, calculate a transparency value in the range 0.0 to 1.0
   // based on how much more intense the green element is
   tempColor.a = 1.0 - smoothstep(0.00, 0.80, gDelta);
   
   // Use the cube of the of the transparency value. That way, a fragment that
   // is partially translucent becomes even more translucent. This sharpens
   // the final result by avoiding almost but not quite opaque fragments that
   // tend to form halos at color boundaries.
   tempColor.a = tempColor.a * tempColor.a * tempColor.a;
      
	gl_FragColor = tempColor;
}


