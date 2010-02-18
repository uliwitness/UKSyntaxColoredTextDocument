//
//  UKSyntaxColoredTextDocument.h
//  CocoaTADS
//
//  Created by Uli Kusterer on Tue May 27 2003.
//  Copyright (c) 2003 M. Uli Kusterer. All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import "UKTextDocGotoBox.h"

// Define the constant below to 0 if you don't need support for old-style
//  (pre-0.2.0) syntax definition files. Old-style syntax definitions are being
//  phased out. Remember to update your definitions to the new one!
#ifndef TD_BACKWARDS_COMPATIBLE
#define TD_BACKWARDS_COMPATIBLE		1
#endif

// Attribute values for TD_SYNTAX_COLORING_MODE_ATTR added along with styles to program text:
//		These are only used for old-style syntax definitions. The post-0.2 style allows whatever
//		names you choose for the styles.
#if TD_BACKWARDS_COMPATIBLE
#define	TD_MULTI_LINE_COMMENT_ATTR			@"SyntaxColoring:MultiLineComment"		// Multi-line comment.
#define	TD_MULTI_LINE_COMMENT2_ATTR			@"SyntaxColoring:MultiLineComment2"		// A second kind of multi-line comment.
#define	TD_ONE_LINE_COMMENT_ATTR			@"SyntaxColoring:OneLineComment"		// One-line comment.
#define	TD_DOUBLE_QUOTED_STRING_ATTR		@"SyntaxColoring:DoubleQuotedString"	// Double-quoted string.
#define	TD_SINGLE_QUOTED_STRING_ATTR		@"SyntaxColoring:SingleQuotedString"	// ** unused **
#define	TD_PREPROCESSOR_ATTR				@"SyntaxColoring:Preprocessor"			// Preprocessor directive.
#define	TD_IDENTIFIER_ATTR					@"SyntaxColoring:Identifier"			// Identifier.
#define	TD_IDENTIFIER2_ATTR					@"SyntaxColoring:Identifier2"			// Identifier from group 2.
#define	TD_TAG_ATTR							@"SyntaxColoring:Tag"					// An HTML tag.
#endif

#define TD_USER_DEFINED_IDENTIFIERS			@"SyntaxColoring:UserIdentifiers"		// Key in user defaults holding user-defined identifiers to colorize.
#define TD_SYNTAX_COLORING_MODE_ATTR		@"UKTextDocumentSyntaxColoringMode"		// Anything we colorize gets this attribute.

// Syntax-colored text file viewer:
@interface UKSyntaxColoredTextDocument : NSDocument
{
	IBOutlet NSTextView*			textView;				// The text view used for editing code.
	IBOutlet NSProgressIndicator*	progress;				// Progress indicator while coloring syntax.
	IBOutlet NSTextField*			status;					// Status display for things like syntax coloring or background syntax checks.
	IBOutlet UKTextDocGoToBox*		gotoPanel;				// Controller for our "go to line" panel.
	IBOutlet NSImageView*			selectionKindImage;		// Image indicating whether it's an insertion mark or a selection range.
	NSString*						sourceCode;				// Temp. storage for data from file until NIB has been read.
	BOOL							autoSyntaxColoring;		// Automatically refresh syntax coloring when text is changed?
	BOOL							maintainIndentation;	// Keep new lines indented at same depth as their predecessor?
	NSTimer*						recolorTimer;			// Timer used to do the actual recoloring a little while after the last keypress.
	BOOL							syntaxColoringBusy;		// Set while recolorRange is busy, so we don't recursively call recolorRange.
	NSRange							affectedCharRange;
	NSString*						replacementString;
}

+(void) makeSurePrefsAreInited;		// No need to call this.

-(IBAction)	recolorCompleteFile: (id)sender;
-(IBAction)	toggleAutoSyntaxColoring: (id)sender;
-(IBAction)	toggleMaintainIndentation: (id)sender;
-(IBAction) showGoToPanel: (id)sender;
-(IBAction) indentSelection: (id)sender;
-(IBAction) unindentSelection: (id)sender;
-(IBAction)	toggleCommentForSelection: (id)sender;

-(void)		setAutoSyntaxColoring: (BOOL)state;
-(BOOL)		autoSyntaxColoring;

-(void)		setMaintainIndentation: (BOOL)state;
-(BOOL)		maintainIndentation;

-(void)		goToLine: (int)lineNum;
-(void)		goToCharacter: (int)charNum;
-(void)		goToRangeFrom: (int)startCh toChar: (int)endCh;

// Override any of the following in one of your subclasses to customize this object further:
-(NSString*)		syntaxDefinitionFilename;   // Defaults to "SyntaxDefinition.plist" in the app bundle's "Resources" directory.
-(NSDictionary*)	syntaxDefinitionDictionary; // Defaults to loading from -syntaxDefinitionFilename.

-(NSDictionary*)	defaultTextAttributes;		// Style attributes dictionary for an NSAttributedString.

// Private:
-(void) turnOffWrapping;

-(void) recolorRange: (NSRange) range;
#if TD_BACKWARDS_COMPATIBLE
-(void) oldRecolorRange: (NSRange)range;	// Called by recolorRange as needed.
#endif

-(void)	colorOneLineComment: (NSString*) startCh inString: (NSMutableAttributedString*) s
				withColor: (NSColor*) col andMode:(NSString*)attr;
-(void)	colorCommentsFrom: (NSString*) startCh to: (NSString*) endCh inString: (NSMutableAttributedString*) s
				withColor: (NSColor*) col andMode:(NSString*)attr;
-(void)	colorIdentifier: (NSString*) ident inString: (NSMutableAttributedString*) s
				withColor: (NSColor*) col andMode:(NSString*)attr charset: (NSCharacterSet*)cset;
-(void)	colorStringsFrom: (NSString*) startCh to: (NSString*) endCh inString: (NSMutableAttributedString*) s
				withColor: (NSColor*) col andMode:(NSString*)attr andEscapeChar: (NSString*)vStringEscapeCharacter;
-(void)	colorTagFrom: (NSString*) startCh to: (NSString*)endCh inString: (NSMutableAttributedString*) s
				withColor: (NSColor*) col andMode:(NSString*)attr exceptIfMode: (NSString*)ignoreAttr;


@end



// Support for external editor interface:
//	(Doesn't really work yet ... *sigh*)

#pragma options align=mac68k

struct SelectionRange
{
	short   unused1;	// 0 (not used)
	short   lineNum;	// line to select (< 0 to specify range)
	long	startRange; // start of selection range (if line < 0)
	long	endRange;   // end of selection range (if line < 0)
	long	unused2;	// 0 (not used)
	long	theDate;	// modification date/time
};

#pragma options align=reset

