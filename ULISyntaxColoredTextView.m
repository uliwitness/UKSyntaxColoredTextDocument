//
//  ULISyntaxColoredTextView.m
//  UKSyntaxColoredDocument
//
//  Created by Uli Kusterer on 17/06/16.
//
//

#import "ULISyntaxColoredTextView.h"
#import "UKSyntaxColoredTextViewController.h"
#import <QuartzCore/QuartzCore.h>


#define INSERTION_INDICATOR_SIZE		5
#define INSERTION_INDICATOR_LINE_WIDTH	2
#define HALF_INSERTION_INDICATOR		((int)INSERTION_INDICATOR_SIZE / 2)


@interface ULISyntaxColoredTextView	()
{
	NSRange			_rangeForUserTextChangeOverride;
	CAShapeLayer *	_lineInsertionIndicatorLayer;
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
		pos.y = self.bounds.size.height -pos.y;
		
		NSRect	usedBox = [self.layoutManager boundingRectForGlyphRange: NSMakeRange(0,FLT_MAX) inTextContainer: self.textContainer];
		
		NSRect		lineFragmentBox = {};
		if( NSPointInRect(pos,usedBox) )
		{
			CGFloat		insertionMarkFraction = 0;
			pos.x = 4;
			NSUInteger	charIndex = [self.layoutManager characterIndexForPoint: pos inTextContainer: self.textContainer fractionOfDistanceBetweenInsertionPoints: &insertionMarkFraction];
			NSUInteger	theGlyphIdx = [self.layoutManager glyphIndexForCharacterAtIndex: charIndex];
			NSRange		effectiveRange = { 0, 0 };
			lineFragmentBox = [self.layoutManager lineFragmentRectForGlyphAtIndex:theGlyphIdx effectiveRange: &effectiveRange];
			
			_rangeForUserTextChangeOverride = NSMakeRange(charIndex,0);
		}
		else
		{
			_rangeForUserTextChangeOverride = NSMakeRange(self.textStorage.length, 0);
			lineFragmentBox = usedBox;
			lineFragmentBox.origin.y += usedBox.size.height;
			usedBox.size.height = 0;
		}
		
		if( [self.delegate respondsToSelector: @selector(syntaxColoredTextView:willInsertSnippetInRange:)] )
		{
			[(id<ULISyntaxColoredTextViewDelegate>)self.delegate syntaxColoredTextView: self willInsertSnippetInRange: &_rangeForUserTextChangeOverride];
		}
		
		if( _rangeForUserTextChangeOverride.location == NSNotFound )
		{
			[_lineInsertionIndicatorLayer removeFromSuperlayer];
			_lineInsertionIndicatorLayer = nil;
		}
		else if( !_lineInsertionIndicatorLayer )
		{
			_lineInsertionIndicatorLayer = [CAShapeLayer layer];
			CGMutablePathRef insertionIndicatorPath = CGPathCreateMutable();
			CGPathAddEllipseInRect( insertionIndicatorPath, NULL, CGRectMake(0,0,INSERTION_INDICATOR_SIZE,INSERTION_INDICATOR_SIZE) );
			CGPathMoveToPoint( insertionIndicatorPath, NULL, INSERTION_INDICATOR_SIZE, ((int)INSERTION_INDICATOR_SIZE / 2) );
			CGPathAddLineToPoint( insertionIndicatorPath, NULL, 132, HALF_INSERTION_INDICATOR );
			_lineInsertionIndicatorLayer.lineWidth = 2;
			_lineInsertionIndicatorLayer.lineCap = kCALineCapRound;
			_lineInsertionIndicatorLayer.anchorPoint = NSMakePoint(0,0.5);
			_lineInsertionIndicatorLayer.strokeColor = [NSColor blueColor].CGColor;
			_lineInsertionIndicatorLayer.fillColor = nil;
			_lineInsertionIndicatorLayer.path = insertionIndicatorPath;
			[self.layer addSublayer: _lineInsertionIndicatorLayer];
		}
		
		if( _lineInsertionIndicatorLayer )
		{
			[CATransaction begin];
			[CATransaction setDisableActions: YES];
				_lineInsertionIndicatorLayer.position = NSMakePoint(((int)INSERTION_INDICATOR_LINE_WIDTH / 2),NSMinY(lineFragmentBox) -HALF_INSERTION_INDICATOR);
			[CATransaction commit];
			
			return NSDragOperationCopy;
		}
		else
		{
			return NSDragOperationNone;
		}
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
		NSString * theString = nil;
		if( [self.delegate respondsToSelector: @selector(syntaxColoredTextView:willInsertSnippetInRange:)] )
		{
			theString = [(id<ULISyntaxColoredTextViewDelegate>)self.delegate syntaxColoredTextView: self stringForSnippedOnPasteboard: pboard];
		}
		else
		{
			theString = [pboard stringForType: self.customSnippetPasteboardType];
		}
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
	
	[_lineInsertionIndicatorLayer removeFromSuperlayer];
	_lineInsertionIndicatorLayer = nil;
	_rangeForUserTextChangeOverride = NSMakeRange(NSNotFound,0);
}

@end
