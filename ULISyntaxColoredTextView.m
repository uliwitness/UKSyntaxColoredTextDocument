//
//  ULISyntaxColoredTextView.m
//  UKSyntaxColoredDocument
//
//  Created by Uli Kusterer on 17/06/16.
//
//

#import "ULISyntaxColoredTextView.h"
#import "UKSyntaxColoredTextViewController.h"


@implementation ULISyntaxColoredTextView

-(void) keyDown:(NSEvent *)event
{
	NSString * pressedChars = [event charactersIgnoringModifiers];
	if( pressedChars.length == 0 )
	{
		[super keyDown: event];
		return;
	}
	unichar theCh = [pressedChars characterAtIndex: 0];
	if( theCh == 0x03 )	// Enter key.
	{
		id<ULISyntaxColoredTextViewDelegate>	theDelegate = (id<ULISyntaxColoredTextViewDelegate>)self.delegate;
		if( [theDelegate respondsToSelector: @selector(syntaxColoredTextViewHandleEnterKey:)] )
		{

			if( [theDelegate respondsToSelector: @selector(syntaxColoredTextViewShouldHandleEnterKey:)]
				&& [theDelegate syntaxColoredTextViewShouldHandleEnterKey: self] )
			{
				[theDelegate syntaxColoredTextViewHandleEnterKey: self];
				return;
			}
		}
	}

	[super keyDown: event];
}


-(void)	insertNewline:(id)sender
{
	if( ![(UKSyntaxColoredTextViewController*)self.delegate maintainIndentation] )
	{
		[super insertNewline: sender];
		return;
	}
	NSRange						affectedCharRange = self.selectedRange;
	NSMutableAttributedString*  textStore = [self textStorage];
	BOOL						hadSpaces = NO;
	NSUInteger					lastSpace = affectedCharRange.location,
								prevLineBreak = 0;
	NSRange						spacesRange = { 0, 0 };
	unichar						theChar = 0;
	NSUInteger					x = (affectedCharRange.location == 0) ? 0 : affectedCharRange.location -1;
	NSString*					tsString = [textStore string];
	if( tsString.length == 0 )
	{
		[super insertNewline: sender];
		return;
	}
	
	while( YES )
	{
		if( x > ([tsString length] -1) )
			break;
		
		theChar = [tsString characterAtIndex: x];
		
		switch( theChar )
		{
			case '\n':
			case '\r':
				prevLineBreak = x +1;
				x = 0;  // Terminate the loop.
				break;
			
			case ' ':
			case '\t':
				if( !hadSpaces )
				{
					lastSpace = x;
					hadSpaces = YES;
				}
				break;
			
			default:
				hadSpaces = NO;
				break;
		}
		
		if( x == 0 )
			break;
		
		x--;
	}
	
	[self.undoManager beginUndoGrouping];
	NSRange		newlineAndSpacesRange = self.selectedRange;
	newlineAndSpacesRange.length = 1;
	NSRange		replacementRange = self.selectedRange;
	[self insertText: @"\n" replacementRange: replacementRange];
	replacementRange.location += newlineAndSpacesRange.length;
	replacementRange.length = 0;
	if( hadSpaces )
	{
		spacesRange.location = prevLineBreak;
		spacesRange.length = lastSpace -prevLineBreak +1;
		if( spacesRange.length > 0 )
		{
			newlineAndSpacesRange.length += spacesRange.length;
			[self insertText: [tsString substringWithRange:spacesRange] replacementRange: replacementRange];
		}
	}
	[self.undoManager endUndoGrouping];
}

@end
