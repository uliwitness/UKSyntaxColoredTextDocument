//
//  UKSCTDUserIdentifiersPrefsController.m
//  UKSyntaxColoredDocument
//
//  Created by Uli Kusterer on Sat May 15 2004.
//  Copyright (c) 2004 M. Uli Kusterer. All rights reserved.
//

// -----------------------------------------------------------------------------
//	Headers:
// -----------------------------------------------------------------------------

#import "UKSCTDUserIdentifiersPrefsController.h"
#import "UKSyntaxColoredTextDocument.h"


@implementation UKSCTDUserIdentifiersPrefsController

// -----------------------------------------------------------------------------
//	* CONSTRUCTOR:
//
//	REVISIONS:
//		2004-05-18	witness	Documented.
// -----------------------------------------------------------------------------

-(id) init
{
	self = [super init];
	if( self )
	{
		identifiers = nil;  // Is instantiated lazily when we need it.
	}
	
	return self;
}


// -----------------------------------------------------------------------------
//	* DESTRUCTOR:
//
//	REVISIONS:
//		2004-05-18	witness	Documented.
// -----------------------------------------------------------------------------

-(void) dealloc
{
    [identifiers release];
    identifiers = nil;

    [super dealloc];
}


// -----------------------------------------------------------------------------
//	awakeFromNib:
//		Make sure GUI looks right after it's been loaded.
//
//	REVISIONS:
//		2004-05-18	witness	Documented.
// -----------------------------------------------------------------------------

-(void) awakeFromNib
{
	[self tableViewSelectionDidChange:nil]; // Make sure "remove" button looks right.
}


// -----------------------------------------------------------------------------
//	createNewIdentifier:
//		Action for "Add Identifier" button. Creates a new untitled identifier
//		entry that the user can then edit.
//
//	REVISIONS:
//		2004-05-18	witness	Documented.
// -----------------------------------------------------------------------------

-(IBAction) createNewIdentifier: (id)sender
{
	[[self identifiers] addObject: NSLocalizedString(@"untitled", nil)];
	int		theRow = [[self identifiers] count] -1;

	[identifiersList noteNumberOfRowsChanged];
	
	[identifiersList selectRow: theRow byExtendingSelection: NO];
	[identifiersList editColumn: 0 row: theRow withEvent: nil select: YES];
}


// -----------------------------------------------------------------------------
//	deleteIdentifier:
//		Action for "Remove Identifier" button. Removes the selected identifier
//		from the list and the user defaults.
//
//	REVISIONS:
//		2004-05-18	witness	Documented.
// -----------------------------------------------------------------------------

-(IBAction) deleteIdentifier: (id)sender
{
	[identifiers removeObjectAtIndex: [identifiersList selectedRow]];
	[identifiersList noteNumberOfRowsChanged];

	[[NSUserDefaults standardUserDefaults] setObject: [self identifiers]
		forKey: TD_USER_DEFINED_IDENTIFIERS];
}


// -----------------------------------------------------------------------------
//	identifiers:
//		Return and, if needed, lazily instantiate our array of user-defined
//		identifiers.
//
//	REVISIONS:
//		2004-05-18	witness	Documented.
// -----------------------------------------------------------------------------

-(NSMutableArray*)  identifiers
{
	if( !identifiers )
	{
		identifiers = [[[NSUserDefaults standardUserDefaults] objectForKey: TD_USER_DEFINED_IDENTIFIERS] mutableCopy];
		if( !identifiers )
			identifiers = [[NSMutableArray alloc] init];
	}
	
	return identifiers;
}


// -----------------------------------------------------------------------------
//	Table view data source methods:
// -----------------------------------------------------------------------------

-(int)  numberOfRowsInTableView:(NSTableView *)tableView
{
	return [[self identifiers] count];
}


-(void) tableViewSelectionDidChange:(NSNotification *)notification
{
	[removeButton setEnabled: ([identifiersList selectedRow] != -1)];   // Make sure "remove" button is only enabled if we have a selection.
}


-(id)   tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	return [[self identifiers] objectAtIndex: row];
}


-(void) tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	[identifiers replaceObjectAtIndex: row withObject: object];
	
	[[NSUserDefaults standardUserDefaults] setObject: [self identifiers]
		forKey: TD_USER_DEFINED_IDENTIFIERS];
}



@end
