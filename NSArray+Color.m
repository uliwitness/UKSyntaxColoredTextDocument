//
//  NSArray+Color.m
//  CocoaTADS
//
//  Created by Uli Kusterer on Mon Jun 02 2003.
//  Copyright (c) 2003 M. Uli Kusterer. All rights reserved.
//

// -----------------------------------------------------------------------------
//  Headers:
// -----------------------------------------------------------------------------

#import "NSArray+Color.h"


@implementation NSArray (Color)

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
	float			fRed, fGreen, fBlue, fAlpha;
	
	col = [col colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
	[col getRed: &fRed green: &fGreen blue: &fBlue alpha: &fAlpha];
	
	return [self arrayWithObjects: [NSNumber numberWithFloat:fRed], [NSNumber numberWithFloat:fGreen],
									[NSNumber numberWithFloat:fBlue], [NSNumber numberWithFloat:fAlpha], nil];
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
	float			fRed, fGreen, fBlue, fAlpha = 1.0;
	
	fRed = [[self objectAtIndex:0] floatValue];
	fGreen = [[self objectAtIndex:1] floatValue];
	fBlue = [[self objectAtIndex:2] floatValue];
	if( [self count] > 3 )	// Have alpha info?
		fAlpha = [[self objectAtIndex:3] floatValue];
	
	return [NSColor colorWithCalibratedRed: fRed green: fGreen blue: fBlue alpha: fAlpha];
}

@end
