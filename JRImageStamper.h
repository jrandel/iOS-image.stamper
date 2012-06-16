//
//  JRImageStamper.h
//
//  Created by jason on 6/15/12.
//  Copyright 2012 Jason C. Randel. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface JRImageStamper : NSObject {
	UIImage *_image;
	CGRect _imageFrame;
	CGAffineTransform _transform;
	UIImage *_stampImage;
	CGRect _initialStampFrame;
	CGSize _imageFrameOffset;
}

@property (nonatomic, retain) UIImage *image;
@property CGAffineTransform transform;
@property (nonatomic, retain) UIImage *stampImage;
@property CGRect imageFrame;
@property CGRect initialStampFrame;
@property CGSize imageFrameOffset;

+ (JRImageStamper *)imageStamperWithImage:(UIImage *)anImage 
							   imageFrame:(CGRect)imageRect
								transform:(CGAffineTransform)aTransform 
									stamp:(UIImage *)aStamp 
						initialStampFrame:(CGRect)stampRect;

- (UIImage *)stampedImage;

- (void)appendTransform:(CGAffineTransform)anotherTransform;

@end
