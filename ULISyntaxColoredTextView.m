//
//  ULISyntaxColoredTextView.m
//  UKSyntaxColoredDocument
//
//  Created by Uli Kusterer on 17/06/16.
//
//

#import "ULISyntaxColoredTextView.h"
#import "UKSyntaxColoredTextViewController.h"


@interface ULISyntaxColoredTextView	()
{
	NSRange _rangeForUserTextChangeOverride;
}

@end


@implementation ULISyntaxColoredTextView

-(instancetype) initWithCoder: (NSCoder *)coder
{
	self = [super initWithCoder: coder];
	if( self )
	{
		_rangeForUserTextChangeOverride.location = NSNotFound;
	}
	
	return self;
}


-(instancetype) initWithFrame: (NSRect)frameRect
{
	self = [super initWithFrame: frameRect];
	if( self )
	{
		_rangeForUserTextChangeOverride.location = NSNotFound;
	}
	
	return self;
}


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


-(NSArray<NSString*>*) readablePasteboardTypes
{
	if( self.customSnippetPasteboardType == nil )
	{
		return [super readablePasteboardTypes];
	}
	else
	{
		return [[NSArray arrayWithObject: self.customSnippetPasteboardType] arrayByAddingObjectsFromArray: [super readablePasteboardTypes]];
	}
}


-(NSArray<NSString*>*) acceptableDragTypes
{
	if( self.customSnippetPasteboardType == nil )
	{
		return [super acceptableDragTypes];
	}
	else
	{
		return [[NSArray arrayWithObject: self.customSnippetPasteboardType] arrayByAddingObjectsFromArray: [super acceptableDragTypes]];
	}
}


-(NSRange) rangeForUserTextChange
{
	if( _rangeForUserTextChangeOverride.location == NSNotFound )
		return [super rangeForUserTextChange];
	else
		return _rangeForUserTextChangeOverride;
}


-(NSDragOperation)	dragOperationForDraggingInfo: (id <NSDraggingInfo>)dragInfo type: (NSString *)type
{
	if( [self.customSnippetPasteboardType isEqualToString: type] && self.customSnippetsInsertionGranularity == NSSelectByParagraph )
	{
		NSPoint pos = dragInfo.draggingLocation;
		
		CGFloat		insertionMarkFraction = 0;
		pos.x = 4;
		pos.y = self.bounds.size.height -pos.y;
		NSUInteger	charIndex = [self.layoutManager characterIndexForPoint: pos inTextContainer: self.textContainer fractionOfDistanceBetweenInsertionPoints: &insertionMarkFraction];

		_rangeForUserTextChangeOverride = NSMakeRange(charIndex,0);
		
		return NSDragOperationCopy;
	}
	else
	{
		return [super dragOperationForDraggingInfo: dragInfo type: type];
	}
}

-(BOOL)	readSelectionFromPasteboard: (NSPasteboard *)pboard type: (NSString *)type
{
	if( [self.customSnippetPasteboardType isEqualToString: type] )
	{
		[self.undoManager beginUndoGrouping];
		NSString * theString = [pboard stringForType: self.customSnippetPasteboardType];
		NSRange selectedRange = self.rangeForUserTextChange;
		[self insertText: theString replacementRange: selectedRange];
		[self.undoManager endUndoGrouping];
		
		_rangeForUserTextChangeOverride = NSMakeRange(NSNotFound,0);
		
		return YES;
	}
	else
	{
		return [super readSelectionFromPasteboard: pboard type: type];
	}
}


-(void) cleanUpAfterDragOperation
{
	[super cleanUpAfterDragOperation];
	
	_rangeForUserTextChangeOverride = NSMakeRange(NSNotFound,0);
}

@end
