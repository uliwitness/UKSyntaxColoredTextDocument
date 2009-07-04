//
//  UKSCTDUserIdentifiersPrefsController.h
//  UKSyntaxColoredDocument
//
//  Created by Uli Kusterer on Sat May 15 2004.
//  Copyright (c) 2004 M. Uli Kusterer. All rights reserved.
//

/*
	This is a simple controller class that handles changing the list of user-
	defined identifiers that UKSyntaxColoredTextDocument uses (except if the
	Syntax definition provides its own). You simply set up "add" and "remove"
	buttons and a table view, connect them to an instance of this object, and
	it will take care of the rest.
*/

// -----------------------------------------------------------------------------
//	Headers:
// -----------------------------------------------------------------------------

#import <Foundation/Foundation.h>


// -----------------------------------------------------------------------------
//	Class:
// -----------------------------------------------------------------------------

@interface UKSCTDUserIdentifiersPrefsController : NSObject
{
	IBOutlet NSTableView*		identifiersList;	// The list view for editing and viewing identifiers. This object is its data source and delegate.
	IBOutlet NSButton*			removeButton;		// The "remove" button so we can enable/disable it.
	NSMutableArray*				identifiers;		// Our internal, editable copy of the list of identifiers.
}

-(IBAction) createNewIdentifier: (id)sender;		// Action for "Add" button.
-(IBAction) deleteIdentifier: (id)sender;			// Action for "Remove" button.

// Private:
-(NSMutableArray*)  identifiers;					// Accessor that lazily instantiates the "identifiers" array when first needed.

@end
