/*  UKTextDocGoToBox 
	(c) 2003 by M. Uli Kusterer, all rights reserved.
	
	This class shows a little "Go to character/line" sheet window and handles
	it until the user is finished with it. This is intended to be instantiated
	from a NIB and hooked up to the outlets of a "go to line" window in the NIB
	there.
	
	Written for UKSyntaxColoredTextDocument.
	
	REVISIONS:
		2004-05-18  witness Documented.
*/

// -----------------------------------------------------------------------------
//  Headers:
// -----------------------------------------------------------------------------

#import <Cocoa/Cocoa.h>


// -----------------------------------------------------------------------------
//  Text doc goto box delegate/target protocol:
// -----------------------------------------------------------------------------

// targetDocument must support this protocol:
@protocol UKTextDocGoToBoxTarget

-(void) goToLine: (int)num;
-(void) goToCharacter: (int)num;

@end


// -----------------------------------------------------------------------------
//  Class:
// -----------------------------------------------------------------------------

@interface UKTextDocGoToBox : NSObject
{
    IBOutlet NSPanel						*goToPanel;
    IBOutlet NSMatrix						*lineCharChooser;
    IBOutlet NSTextField					*lineNumField;
    IBOutlet NSButton						*okayButton;
    IBOutlet id	<UKTextDocGoToBoxTarget>	targetDocument;		// Object whom we send goToLine or goToCharacter messages.
}

// This is what you want to call:
-(IBAction) showGoToSheet: (NSWindow*)owner;

// Button actions: (Private)
-(IBAction) goToLineOrChar: (id)sender;
-(IBAction) hideGoToSheet: (id)sender;

@end


