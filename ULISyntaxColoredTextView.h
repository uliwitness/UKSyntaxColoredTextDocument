//
//  ULISyntaxColoredTextView.h
//  UKSyntaxColoredDocument
//
//  Created by Uli Kusterer on 17/06/16.
//
//

#import <Cocoa/Cocoa.h>


@interface ULISyntaxColoredTextView : NSTextView

@property (retain) IBInspectable NSString * customSnippetPasteboardType;
@property IBInspectable NSSelectionGranularity customSnippetsInsertionGranularity;	// Set to NSSelectByParagraph to only allow dropping between lines, NSSelectByCharacter for normal behaviour.

@end


/*!
	Additional delegate methods that the syntax colored text view implements.
*/
@protocol ULISyntaxColoredTextViewDelegate <NSTextViewDelegate>

@optional

// Handle enter key presses differently than return:
-(BOOL) syntaxColoredTextViewShouldHandleEnterKey: (ULISyntaxColoredTextView*)sender;
-(void) syntaxColoredTextViewHandleEnterKey: (ULISyntaxColoredTextView*)sender;

// Handling custom code snippet (drag and) drops:
-(void)		syntaxColoredTextView: (ULISyntaxColoredTextView*)sender willInsertSnippetInRange: (NSRange*)insertionRange;	// Adjust insertionRange if it is not appropriate, or set its location to NSNotFound to not insert. If customSnippetsInsertionGranularity == NSSelectByParagraph, the insertion location is either the start of a line, or after the end of the text.

-(NSString*) syntaxColoredTextView: (ULISyntaxColoredTextView*)sender stringForSnippetOnPasteboard: (NSPasteboard*)pboard forRange: (NSRange)dropRange;	// If your snippet flavor is not raw string data, implement this to unpack it into a string we can insert into the code. Not implementing this will result in -stringForType: being called on the pasteboard and inserting that.

@end


