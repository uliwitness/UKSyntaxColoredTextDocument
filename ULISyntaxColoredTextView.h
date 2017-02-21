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
@property IBInspectable NSSelectionGranularity customSnippetsInsertionGranularity;	// Set to NSSelectByParagraph to only allow dropping at a line start, NSSelectByCharacter for normal behaviour.

@end


/*!
	Additional delegate methods that the syntax colored text view implements.
*/
@protocol ULISyntaxColoredTextViewDelegate <NSTextViewDelegate>

@optional

-(BOOL) syntaxColoredTextViewShouldHandleEnterKey: (ULISyntaxColoredTextView*)sender;
-(void) syntaxColoredTextViewHandleEnterKey: (ULISyntaxColoredTextView*)sender;

@end


