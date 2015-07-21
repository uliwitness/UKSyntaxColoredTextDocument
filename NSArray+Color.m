//
//  NSArray+Color.m
//  CocoaTADS
//
//  Created by Uli Kusterer on Mon Jun 02 2003.
//  Copyright (c) 2003 Uli Kusterer.
//
//	This software is provided 'as-is', without any express or implied
//	warranty. In no event will the authors be held liable for any damages
//	arising from the use of this software.
//
//	Permission is granted to anyone to use this software for any purpose,
//	including commercial applications, and to alter it and redistribute it
//	freely, subject to the following restrictions:
//
//	   1. The origin of this software must not be misrepresented; you must not
//	   claim that you wrote the original software. If you use this software
//	   in a product, an acknowledgment in the product documentation would be
//	   appreciated but is not required.
//
//	   2. Altered source versions must be plainly marked as such, and must not be
//	   misrepresented as being the original software.
//
//	   3. This notice may not be removed or altered from any source
//	   distribution.
//

// -----------------------------------------------------------------------------
//  Headers:
// -----------------------------------------------------------------------------

#import "NSArray+Color.h"

#import "NSNumber+JXCGFloat.h"

@implementation NSArray (UKColor)

// -----------------------------------------------------------------------------
//	arrayWithColor:
//		Converts the color to an RGB color if needed, and then creates an array
//		with its red, green, blue and alpha components (in that order).
//
//  REVISIONS:
//		2004-05-18  witness documented.
// -----------------------------------------------------------------------------

+(NSArray*)		arrayWithColor: (NSColor*) col
{
	CGFloat			fRed = 0, fGreen = 0, fBlue = 0, fAlpha = 1.0;
	
	col = [col colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
	[col getRed: &fRed green: &fGreen blue: &fBlue alpha: &fAlpha];
	
	return @[[NSNumber numberWithCGFloatJX:fRed],
			 [NSNumber numberWithCGFloatJX:fGreen],
			 [NSNumber numberWithCGFloatJX:fBlue],
			 [NSNumber numberWithCGFloatJX:fAlpha]];
}


// -----------------------------------------------------------------------------
//	colorValue:
//		Converts an NSArray with three (or four) NSValues into an RGB Color
//		(plus alpha, if specified).
//
//  REVISIONS:
//		2004-05-18  witness documented.
// -----------------------------------------------------------------------------

-(NSColor*)		colorValue
{
	float			fRed = 0, fGreen = 0, fBlue = 0, fAlpha = 1.0;
	
	if( [self count] >= 3 )
	{
		fRed = [self[0] CGFloatValueJX];
		fGreen = [self[1] CGFloatValueJX];
		fBlue = [self[2] CGFloatValueJX];
	}
	if( [self count] > 3 )	// Have alpha info?
		fAlpha = [self[3] floatValue];
	
	return [NSColor colorWithCalibratedRed: fRed green: fGreen blue: fBlue alpha: fAlpha];
}

@end
