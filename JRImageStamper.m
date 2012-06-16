//
//  JRImageStamper.m
//
//  Created by jason on 6/15/12.
//  Copyright 2012 Jason C. Randel. All rights reserved.
//

#import "JRImageStamper.h"


@implementation JRImageStamper

@synthesize image = _image;
@synthesize stampImage = _stampImage;
@synthesize transform = _transform;
@synthesize imageFrame = _imageFrame;
@synthesize initialStampFrame = _initialStampFrame;
@synthesize imageFrameOffset = _imageFrameOffset;


/* Let's say you have a (PW x PH) photo that you place into a UIImageView that is W x H pixels in size.
   Now, you have another UIImage (from PNG data, let's say, and w x h in size) that you want to stamp on top of this photo.
   The complication is that you want the resulting stamped image to be at full (PWxPH) resolution, not WxH.
   So you can't just take the two layers from a WxH context, and you can't take it from a PWxPH context without
   scaling up the stamping image (w x h).  That's not terrible, unless the stamping image is rotated; then things
   get tricky.  That's what this class solves.
 */

// anImage			:	the large photo to stamp
// aTransform		:	the affine transform that was used to place the stamping image in the 
// transformRect	:	the frame of the UIImageView that anImage was in when the stamp was placed; the transform is described in units of this frame
// aStamp			:	the stamping image
// initialStampFrame:	the position of the stamp's UIImageView prior to applying the transform

// imageStamperWithImage: transform: imageFrame: stamp: initialStampFrame:
//	 returns an autoreleased image stamper populated with the provided instance variables

+ (JRImageStamper *)imageStamperWithImage:(UIImage *)anImage 
							   imageFrame:(CGRect)imageRect
								transform:(CGAffineTransform)aTransform 
									stamp:(UIImage *)aStamp 
						initialStampFrame:(CGRect)stampRect {

	JRImageStamper *stamper = [[JRImageStamper alloc] init];
	stamper.image = anImage;
	stamper.transform = aTransform;
	stamper.imageFrame = imageRect;
	stamper.stampImage = aStamp;
	stamper.initialStampFrame = stampRect;
	stamper.imageFrameOffset = CGSizeMake(0.0, 0.0);
	return [stamper autorelease];
}

// stampedImage
//   Returns a UIImage that is a copy of the image with the stamped image superimposed over it
- (UIImage *)stampedImage {
	
	// determine how big stamp should be (same as the amount photo was scaled down to fit in photoView)
	CGSize imageSize = self.image.size;
	CGSize stampSize = self.stampImage.size;
	CGRect initialStampSize = self.initialStampFrame;
	
	CGFloat imageScaling = MAX(imageSize.width / self.imageFrame.size.width, imageSize.height / self.imageFrame.size.height);
	NSLog(@"Image scaling: %@ / %@", [[NSNumber numberWithDouble:imageSize.width / self.imageFrame.size.width] stringValue],
		  [[NSNumber numberWithDouble:imageSize.height / self.imageFrame.size.height] stringValue]);
	CGFloat roundToNearest = 0.001;
	imageScaling = round(imageScaling / roundToNearest) * roundToNearest;
	
	
	// Begin the drawing in a canvas that is the same size as the original image
	if (UIGraphicsBeginImageContextWithOptions != NULL) {	// this is used for ios4.0+
		UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0.0);
	}		
	else {
		UIGraphicsBeginImageContext(imageSize);		// for ios <4.0 (depricated in 4.0+)
	}
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	
	// DRAW THE PHOTO IN CURRENT IMAGE CONTEXT
	CGRect imageRect = CGRectMake(0.0, 0.0, self.image.size.width, self.image.size.height);
	
	// Clear whole rectangle
	CGContextClearRect(context, imageRect);
	
	// Draw the photo into the context
	[self.image drawInRect:imageRect];
	
	
	// placement of the Stamp image
	CGRect stampRect = CGRectMake(0.0, 0.0, initialStampSize.size.width, initialStampSize.size.height);
	
	// translate into the corner of the image (rather than stamp's final frame)
	CGRect corner = CGRectMake(self.imageFrame.origin.x + self.imageFrameOffset.width, 
							   self.imageFrame.origin.x + self.imageFrameOffset.height, 
							   self.imageFrame.size.width, 
							   self.imageFrame.size.height);
	//CGRect corner = [self photoFrameInPhotoView];
	corner = CGRectMake(corner.origin.x - self.imageFrame.origin.x, corner.origin.y - self.imageFrame.origin.y,
						corner.size.width, corner.size.height);
	
	// scale context up to size of real photo (bottomRect's scale)
	CGContextScaleCTM(context, imageScaling, imageScaling);
	CGContextTranslateCTM(context, -corner.origin.x, -corner.origin.y);
	
	// translate, scale, and rotate according to transform
	CGContextConcatCTM(context, self.transform);
	
	
	// account for offset of context origin (upper left) vs. view origin (center)
	CGFloat affineMatrixA = self.transform.a;
	CGFloat affineMatrixB = self.transform.b;
	
	
	// compute rotation angle and scale from affine transform's a and b values
	CGFloat theAngle;
	CGFloat theScale = -1.0;
	
	// angle
	if (affineMatrixA != 0.0 || affineMatrixB != 0.0) {
		theAngle = atan2(affineMatrixB, affineMatrixA);
	}
	else {	// both A and B are zero, so scale is zero (stamp has size (0,0))
		theAngle = 0.0;
	}
	
	// scale
	if (affineMatrixA != 0.0) {
		theScale = affineMatrixA/cos(theAngle);
	}
	else if (affineMatrixB != 0.0) {
		theScale = affineMatrixB/sin(theAngle);
	}
	else {
		theScale = 0.0;
	}
	
	// determine offset vector along new (rotated, scaled) unit vector directions
	CGPoint offsetVector = CGPointMake(	 stampRect.size.width / 2.0 * cos(theAngle) 
									   + stampRect.size.height / 2.0 * sin(theAngle) 
									   - theScale * stampRect.size.width / 2.0 , 
									   stampRect.size.height / 2.0 * cos(theAngle) 
									   - stampRect.size.width / 2.0 * sin(theAngle) 
									   - theScale * stampRect.size.height / 2.0);
	
	CGPoint scaledOffsetVector = CGPointMake(offsetVector.x / theScale, offsetVector.y / theScale);
	
	CGContextTranslateCTM(context, scaledOffsetVector.x, scaledOffsetVector.y);
	
	// draw the stamp into the context
	[self.stampImage drawInRect:stampRect];
	
	UIImage *stampedImage = nil;
	stampedImage = UIGraphicsGetImageFromCurrentImageContext();
	return stampedImage;
}


- (void)appendTransform:(CGAffineTransform)anotherTransform {
	self.transform = CGAffineTransformConcat(self.transform, anotherTransform);
}

- (void)dealloc {
	[super dealloc];
	[_image release];
	[_stampImage release];
}


@end
