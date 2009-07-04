//
//  UKSCTDColorWellPrefsController.h
//  CocoaTADS
//
//  Created by Uli Kusterer on Wed Feb 11 2004.
//  Copyright (c) 2004 M. Uli Kusterer. All rights reserved.
//

/*
	This is a simple controller class for displaying and changing the colors
	used for syntax coloring.
	
	Simply hook up the outlets to the NSColorWells of your "Preferences" window
	and then connect their actions to the corresponding takeXXXColorFrom:
	methods of an instance of this object.
*/

// -----------------------------------------------------------------------------
//  Headers:
// -----------------------------------------------------------------------------

#import <Foundation/Foundation.h>


// -----------------------------------------------------------------------------
//  Class:
// -----------------------------------------------------------------------------

@interface UKSCTDColorWellPrefsController : NSObject
{
	IBOutlet NSColorWell*		commentsColor;		// Make these point at the NSColorWells.
	IBOutlet NSColorWell*		identifiersColor;
	IBOutlet NSColorWell*		preprocessorColor;
	IBOutlet NSColorWell*		stringsColor;
	IBOutlet NSColorWell*		tagsColor;
	IBOutlet NSColorWell*		identifiers2Color;
	IBOutlet NSColorWell*		comments2Color;
}

// Actions for NSColorWells:
-(IBAction)		takeCommentsColorFrom: (NSColorWell*)cw;
-(IBAction)		takeIdentifiersColorFrom: (NSColorWell*)cw;
-(IBAction)		takePreprocessorColorFrom: (NSColorWell*)cw;
-(IBAction)		takeStringsColorFrom: (NSColorWell*)cw;
-(IBAction)		takeTagsColorFrom: (NSColorWell*)cw;
-(IBAction)		takeIdentifiers2ColorFrom: (NSColorWell*)cw;
-(IBAction)		takeComments2ColorFrom: (NSColorWell*)cw;

-(IBAction)		resetColors: (id)sender;	// For "reset to defaults" button.

// Private:
-(void)			updateUIFromPrefs: (id)sender;

@end
