//
//  GSVideoProcessor.m
//  GreenScreen
//
/*
Copyright (c) 2012 Erik M. Buck

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#import <MobileCoreServices/MobileCoreServices.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "GSVideoProcessor.h"

@interface GSVideoProcessor ()
@end

@implementation GSVideoProcessor

@synthesize delegate;

#pragma mark Capture

/////////////////////////////////////////////////////////////////
// 
- (void)captureOutput:(AVCaptureOutput *)captureOutput
    didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{	    
	if (connection == videoConnection) {        
        // Enqueue it for preview.  This is a shallow queue, so if image
        // processing is taking too long, we'll drop this frame for preview (this
        // keeps preview latency low).
		OSStatus err = CMBufferQueueEnqueue(previewBufferQueue, sampleBuffer);
		if (!err) {        
			dispatch_async(dispatch_get_main_queue(), ^{
				CMSampleBufferRef sbuf = (CMSampleBufferRef)CMBufferQueueDequeueAndRetain(previewBufferQueue);
                  
				if (sbuf) {
					CVImageBufferRef pixBuf = CMSampleBufferGetImageBuffer(sbuf);
					[self.delegate pixelBufferReadyForDisplay:pixBuf];
					CFRelease(sbuf);
				}
			});
		}
	}
}


/////////////////////////////////////////////////////////////////
// 
- (AVCaptureDevice *)videoDeviceWithPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices)
        if ([device position] == position)
            return device;
    
    return nil;
}


/////////////////////////////////////////////////////////////////
// 
- (BOOL) setupCaptureSession 
{
    /* Create capture session */
    captureSession = [[AVCaptureSession alloc] init];
    
	/* Create video connection */
    AVCaptureDeviceInput *videoIn = [[AVCaptureDeviceInput alloc] initWithDevice:[self videoDeviceWithPosition:AVCaptureDevicePositionBack] error:nil];
       
    if ([captureSession canAddInput:videoIn]) {
        [captureSession addInput:videoIn];
    }
    captureSession.sessionPreset = AVCaptureSessionPresetMedium;
    
	AVCaptureVideoDataOutput *videoOut = [[AVCaptureVideoDataOutput alloc] init];
	/* Processing can take longer than real-time on some platforms.
       Clients whose image processing is faster than real-time should consider
       setting AVCaptureVideoDataOutput's alwaysDiscardsLateVideoFrames property
       to NO.
     */
	[videoOut setAlwaysDiscardsLateVideoFrames:YES];
	[videoOut setVideoSettings: @{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)}];
	dispatch_queue_t videoCaptureQueue = dispatch_queue_create("Video Capture Queue", DISPATCH_QUEUE_SERIAL);
	[videoOut setSampleBufferDelegate:self queue:videoCaptureQueue];
	dispatch_release(videoCaptureQueue);
    
	if ([captureSession canAddOutput:videoOut]) {
		[captureSession addOutput:videoOut];
    }
    
	videoConnection = [videoOut connectionWithMediaType:AVMediaTypeVideo];
	return YES;
}


/////////////////////////////////////////////////////////////////
// 
- (void) setupAndStartCaptureSession
{
	// Create a shallow queue for buffers going to the display for preview.
	OSStatus err = CMBufferQueueCreate(
      kCFAllocatorDefault,
      1,
      CMBufferQueueGetCallbacksForUnsortedSampleBuffers(),
      &previewBufferQueue);
      
	if (err) {
		[self showError:[NSError errorWithDomain:NSOSStatusErrorDomain
                                            code:err
                                        userInfo:nil]];
   }
	
    if (!captureSession) {
		 [self setupCaptureSession];
    }
	
	if (!captureSession.isRunning) {
		[captureSession startRunning];
   }
}


/////////////////////////////////////////////////////////////////
// 
- (void) stopAndTearDownCaptureSession
{
   [captureSession stopRunning];
	if (captureSession) {
		[[NSNotificationCenter defaultCenter]
         removeObserver:self
         name:AVCaptureSessionDidStopRunningNotification
         object:captureSession];
    }
   
	captureSession = nil;
	if (previewBufferQueue) {
		CFRelease(previewBufferQueue);
		previewBufferQueue = NULL;	
	}
}


#pragma mark Error Handling

/////////////////////////////////////////////////////////////////
// 
- (void)showError:(NSError *)error
{
    CFRunLoopPerformBlock(
       CFRunLoopGetMain(),
       kCFRunLoopCommonModes,
       ^(void)
       {
          UIAlertView *alertView =
             [[UIAlertView alloc] initWithTitle:
                [error localizedDescription]
                message:[error localizedFailureReason]
                delegate:nil
                cancelButtonTitle:@"OK"
                otherButtonTitles:nil];
        [alertView show];
    });
}

@end
