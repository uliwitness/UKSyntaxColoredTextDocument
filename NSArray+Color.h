//
//  NSArray+Color.h
//  CocoaTADS
//
//  Created by Uli Kusterer on Mon Jun 02 2003.
//  Copyright (c) 2003 M. Uli Kusterer. All rights reserved.
//

// -----------------------------------------------------------------------------
//	Headers:
// -----------------------------------------------------------------------------

#import <Foundation/Foundation.h>


// -----------------------------------------------------------------------------
//	Category:
// -----------------------------------------------------------------------------

// Methods to treat an NSArray with three/four elements as an RGB/RGBA color.
//  Useful for storing colors in NSUserDefaults and other Property Lists.
//  Note that this isn't quite the same as storing an NSData of the color, as
//  some colors can't be correctly represented in RGB, but this makes for more
//  readable property lists than NSData.
// If we wanted to get fancy, we could use an NSDictionary instead and save
//	different color types in different ways.

@interface NSArray (Color)

+(NSArray*)		arrayWithColor: (NSColor*) col;
-(NSColor*)		colorValue;

@end
