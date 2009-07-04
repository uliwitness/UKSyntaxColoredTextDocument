#import "UKTextDocGoToBox.h"

@implementation UKTextDocGoToBox

// -----------------------------------------------------------------------------
//	showGoToSheet:
//		Show the "go to line/character" sheet on the specified window. This will
//		return immediately and you should just ignore its existence until the
//		user closes it, at which point targetDocument will get a goToLine: or
//		goToChar message.
//
//	REVISIONS:
//		2004-05-18	witness	Documented.
// -----------------------------------------------------------------------------

-(IBAction) showGoToSheet: (NSWindow*)owner
{
	[[NSApplication sharedApplication] beginSheet:goToPanel modalForWindow:owner modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
}


// -----------------------------------------------------------------------------
//	hideGoToSheet:
//		Called by the "Cancel" and "OK" buttons to close the sheet once they're
//		done.
//
//	REVISIONS:
//		2004-05-18	witness	Documented.
// -----------------------------------------------------------------------------

-(IBAction) hideGoToSheet: (id)sender
{
	[[NSApplication sharedApplication] endSheet: goToPanel];
}


// -----------------------------------------------------------------------------
//	sheetDidEnd:
//		Called when endSheet has been called on our sheet to actually unmap
//		the window.
//
//	REVISIONS:
//		2004-05-18	witness	Documented.
// -----------------------------------------------------------------------------

-(void) sheetDidEnd: (NSWindow*)sheet returnCode: (int)returnCode contextInfo: (void*)contextInfo
{
	[sheet orderOut: nil];
}


// -----------------------------------------------------------------------------
//	goToLineOrChar:
//		Button action for the "OK" button. This sends the target document the
//		proper goToLine: or goToChar: message and then calls hideGoToSheet: to
//		close the sheet.
//
//	REVISIONS:
//		2004-05-18	witness	Documented.
// -----------------------------------------------------------------------------

-(IBAction) goToLineOrChar:(id)sender
{
	int		num;
	
	num = [lineNumField intValue];
	
	if( [lineCharChooser selectedRow] == 0 )
		[targetDocument goToLine: num];
	else
		[targetDocument goToCharacter: num];
	
	[self hideGoToSheet: sender];
}

@end
