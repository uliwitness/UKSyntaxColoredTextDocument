//
//  ULIFontPickerButton.m
//  Stacksmith
//
//  Created by Uli Kusterer on 01/05/16.
//  Copyright © 2016 Uli Kusterer. All rights reserved.
//

#import "ULIFontPickerButton.h"


#if !__has_feature(objc_arc)
#error This file requires ARC. Please add the -fobjc-arc compiler option for this file.
#endif


@implementation ULIFontPickerButton

-(BOOL)	canBecomeKeyView
{
	return YES;
}


-(BOOL)	acceptsFirstResponder
{
	return YES;
}


-(BOOL)	becomeFirstResponder
{
	[self setState: NSOnState];
	[[NSFontPanel sharedFontPanel] setPanelFont: self.pickedFont isMultiple: NO];
	return YES;
}


-(BOOL)	resignFirstResponder
{
	NSLog(@"resignFirstResponder");
	[self setState: NSOffState];
	return YES;
}


-(void)	changeFont: (nullable id)sender
{
	NSFont*         theFont = self.pickedFont;
	NSFont	*		newFont = [[NSFontPanel sharedFontPanel] panelConvertFont: theFont];
	if( newFont )
		theFont = newFont;
	self.pickedFont = theFont;
}


-(void)	setPickedFont: (NSFont *)pickedFont
{
	_pickedFont = pickedFont;
	self.title = [NSString stringWithFormat: @"%@ – %.1f", _pickedFont.fontName, _pickedFont.pointSize];
	
	[super sendAction: self.action to: self.target];
}

-(BOOL)	sendAction: (SEL)theAction to: (nullable id)theTarget
{
	[self.window makeFirstResponder: self];
	[[NSFontPanel sharedFontPanel] orderFront: self];
	
	return YES;
}

@end
