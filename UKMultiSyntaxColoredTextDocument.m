//
//  UKMultiSyntaxColoredTextDocument.m
//  UKSyntaxColoredDocument
//
//  Created by Uli Kusterer on Mon May 17 2004.
//  Copyright (c) 2004 Uli Kusterer.
//
//	This software is provided 'as-is', without any express or implied
//	warranty. In no event will the authors be held liable for any damages
//	arising from the use of this software.
//
//	Permission is granted to anyone to use this software for any purpose,
//	including commercial applications, and to alter it and redistribute it
//	freely, subject to the following restrictions:
//
//	   1. The origin of this software must not be misrepresented; you must not
//	   claim that you wrote the original software. If you use this software
//	   in a product, an acknowledgment in the product documentation would be
//	   appreciated but is not required.
//
//	   2. Altered source versions must be plainly marked as such, and must not be
//	   misrepresented as being the original software.
//
//	   3. This notice may not be removed or altered from any source
//	   distribution.
//

// -----------------------------------------------------------------------------
//  Headers:
// -----------------------------------------------------------------------------

#import "UKMultiSyntaxColoredTextDocument.h"
#import "NSMenu+DeepSearch.h"


// -----------------------------------------------------------------------------
//  Globals:
// -----------------------------------------------------------------------------

static NSMutableArray*		sUKMSCTDSyntaxDefinitionFiles = nil;	// Array of syntax definition file paths in NSStrings.
static NSMutableDictionary*	sUKMSCTDSuffixToTagMappings = nil;

NSString*	UKMultiSyntaxColoredTextDocumentSyntaxDefinitionChanged = @"UKMultiSyntaxColoredTextDocumentSyntaxDefinitionChanged";


@implementation UKMultiSyntaxColoredTextDocument

// -----------------------------------------------------------------------------
//	syntaxDefinitionFiles:
//		Return and, if needed, lazily allocate the array of available syntax
//		definition files. This also updates the syntax definition menu by
//		writing the file names without suffixes of the syntax definition files
//		into the menu as menu items, whose tags are the indices into the array
//		corresponding to them.
//
//	REVISIONS:
//		2004-05-18	witness	Documented.
//		2004-05-17	witness	Created.
// -----------------------------------------------------------------------------

-(NSArray*) syntaxDefinitionFiles
{
	if( !sUKMSCTDSyntaxDefinitionFiles )
	{
		sUKMSCTDSyntaxDefinitionFiles = [[NSMutableArray alloc] init];
		sUKMSCTDSuffixToTagMappings = [[NSMutableDictionary alloc] init];
		
		// Load from User's Application support:
		NSString*				fpath = [NSString stringWithFormat: @"%@/Library/Application Support/%@/Syntax Definitions/",
											NSHomeDirectory(), UKSCTD_APPLICATION_NAME];
		[self addSyntaxFilesFromFolderToArray: fpath];

		// Load from global application support:
		fpath = [NSString stringWithFormat: @"/Library/Application Support/%@/Syntax Definitions/",
						UKSCTD_APPLICATION_NAME];
		[self addSyntaxFilesFromFolderToArray: fpath];
	
		// Load from folder in app bundle:
		fpath = [[NSBundle mainBundle] pathForResource: @"Syntax Definitions" ofType: @""];
		[self addSyntaxFilesFromFolderToArray: fpath];
		
		// Now make the menu match:
		[self rebuildSyntaxMenu];
	}
	
	return sUKMSCTDSyntaxDefinitionFiles;
}


// -----------------------------------------------------------------------------
//	rebuildSyntaxMenu:
//		Remove the old items from the syntax definition menu and add new menu
//		items for them based on the syntax definition files array.
//
//	REVISIONS:
//		2004-05-18	witness	Extracted from syntaxDefinitionFiles.
// -----------------------------------------------------------------------------

-(void) rebuildSyntaxMenu
{
	NSMenuItem*		foundItem = nil;
	NSMenu*			syntaxMenu = nil;
	
	// Find menu with menu items for syntax definitions:
	if( !syntaxDefinitionMenu )
	{
		foundItem = [[NSApp mainMenu] findItemWithTarget:nil andAction: @selector(takeSyntaxDefinitionFilenameFromTagOf:)];
		syntaxMenu = [foundItem menu];
	}
	else	// If we have a menu in our outlet, use that instead:
	{
		syntaxMenu = syntaxDefinitionMenu;
		foundItem = [syntaxDefinitionMenu itemAtIndex: 0];  // Assume we own the popup.
	}
	
	// Remove all old menu items from our menu:
	NSMenuItem*		currMItem = foundItem;
	int				currItemNum = [syntaxMenu indexOfItem: currMItem];
	
	while( [currMItem action] == @selector(takeSyntaxDefinitionFilenameFromTagOf:) )
	{
		[syntaxMenu removeItem: currMItem];
		if( currItemNum < [syntaxMenu numberOfItems] )
			currMItem = [syntaxMenu itemAtIndex: currItemNum];
		else
			break;
	}
		/* Warning! This croaks if the code below doesn't find any syntax
			definition files, because then all menu items have been removed
			and it won't find the menu the next time! */
	
	NSEnumerator*   enny = [sUKMSCTDSyntaxDefinitionFiles objectEnumerator];
	NSString*		currPath = nil;
	int				x = 0;
	
	while( (currPath = [enny nextObject]) )
	{
		NSString*   dName = [[currPath lastPathComponent] stringByDeletingPathExtension];
		NSMenuItem* currItem = [syntaxMenu addItemWithTitle: dName action: @selector(takeSyntaxDefinitionFilenameFromTagOf:)
									keyEquivalent:@""];
		[currItem setTag: x++]; // Remember array index of this one.
		
		NSDictionary*	dict = [NSDictionary dictionaryWithContentsOfFile: currPath];
		NSEnumerator*	suffixEnny = [[dict objectForKey: @"FileNameSuffixes"] objectEnumerator];
		NSString*		suffix = nil;
		while(( suffix = [suffixEnny nextObject] ))
			[sUKMSCTDSuffixToTagMappings setObject: [NSNumber numberWithInt: x -1] forKey: suffix];
	}
}


// -----------------------------------------------------------------------------
//	addSyntaxFilesFromFolder:
//		Scan the specified folder for files and add all files (except the ones
//		starting with a period) to our array of syntax definition file paths,
//		as well as adding menu items for them.
//
//		This appends to the array, so can be called several times in a row to
//		scan several folders.
//
//	REVISIONS:
//		2004-05-18	witness	Documented.
//		2004-05-17	witness	Created.
// -----------------------------------------------------------------------------

-(void) addSyntaxFilesFromFolderToArray: (NSString*)fpath
{
	NSDirectoryEnumerator*  enny = [[NSFileManager defaultManager] enumeratorAtPath: fpath];
	NSString*				currPath = nil;
	NSString*				currName = nil;
	
	while( (currName = [enny nextObject]) )
	{
		if( [currName characterAtIndex: 0] == '.' )
			continue;
		
		currPath = [fpath stringByAppendingPathComponent: currName];
		[sUKMSCTDSyntaxDefinitionFiles addObject: currPath];
	}
}


// -----------------------------------------------------------------------------
//	reloadSyntaxDefinitionFiles:
//		Kill and recreate the list of syntax definition files.
//
//	REVISIONS:
//		2004-05-18	witness	Created.
// -----------------------------------------------------------------------------

-(void) reloadSyntaxDefinitionFiles
{
	[sUKMSCTDSyntaxDefinitionFiles release];
	sUKMSCTDSyntaxDefinitionFiles = nil;
	
	[self syntaxDefinitionFiles];
}


// -----------------------------------------------------------------------------
//	* CONSTRUCTOR:
//		Lazily instantiate our array of syntax definition file paths and also
//		init the syntax coloring scheme to use to the first item from that list.
//
//	REVISIONS:
//		2004-05-18	witness	Documented.
//		2004-05-17	witness	Created.
// -----------------------------------------------------------------------------

-(id)	init
{
    self = [super init];
    if( self )
	{
		syntaxDefinitionFilename = [[[self syntaxDefinitionFiles] objectAtIndex: 0] retain];
	}
    return self;
}


// -----------------------------------------------------------------------------
//	* DESTRUCTOR:
//
//	REVISIONS:
//		2004-05-18	witness	Documented.
//		2004-05-17	witness	Created.
// -----------------------------------------------------------------------------

-(void) dealloc
{
    [syntaxDefinitionFilename release];
    syntaxDefinitionFilename = nil;

    [super dealloc];
}


// -----------------------------------------------------------------------------
//	windowControllerDidLoadNib:
//		If we're using a popup, reload the syntax definition list now that the
//		NIB's been loaded and in the process populate the menu.
//
//	REVISIONS:
//		2004-05-18	witness	Created.
// -----------------------------------------------------------------------------

-(void) windowControllerDidLoadNib: (NSWindowController *)windowController
{
	if( syntaxDefinitionMenu )  // Connected to a popup in our NIB?
		[self rebuildSyntaxMenu];
	
	NSString*		fileSuffix = [[self fileURL] pathExtension];
	NSNumber*		numObj = [sUKMSCTDSuffixToTagMappings objectForKey: fileSuffix];
	if( numObj )
		[self setSyntaxDefinitionFilename: [sUKMSCTDSyntaxDefinitionFiles objectAtIndex: [numObj intValue]]];
	
	[super windowControllerDidLoadNib: windowController];
}


// -----------------------------------------------------------------------------
//	syntaxDefinitionDictionaryForTextViewController:
//		Return the syntax definition dictionary to use for colorizing. This
//		implements a delegate method in UKSyntaxColoredTextViewController since
//		that only looks for its files in the application bundle.
// -----------------------------------------------------------------------------

-(NSDictionary*)	syntaxDefinitionDictionaryForTextViewController: (UKSyntaxColoredTextViewController*)sender
{
	NSString*   synDefName = [self syntaxDefinitionFilename];	// *not* syntaxDefinitionFilenameForTextViewController:.
	return [NSDictionary dictionaryWithContentsOfFile: synDefName];
}


// -----------------------------------------------------------------------------
//	syntaxDefinitionFilenameForTextViewController:
//		Return the full pathname of the syntax definition file to use for
//		syntax coloring.
// -----------------------------------------------------------------------------

-(NSString*)	syntaxDefinitionFilename
{
    return [[syntaxDefinitionFilename retain] autorelease]; 
}


// -----------------------------------------------------------------------------
//	setSyntaxDefinitionFilename:
//		Select a different syntax definition file name to be used for coloring.
//		This also causes a recoloring of the text using the new coloring scheme.
//
//	REVISIONS:
//		2004-05-18	witness	Documented.
//		2004-05-17	witness	Created.
// -----------------------------------------------------------------------------

-(void) setSyntaxDefinitionFilename:(NSString *)aSyntaxDefinitionFileName
{
    [aSyntaxDefinitionFileName retain];
    [syntaxDefinitionFilename release];
    syntaxDefinitionFilename = aSyntaxDefinitionFileName;
	
	[[NSNotificationCenter defaultCenter] postNotificationName: UKMultiSyntaxColoredTextDocumentSyntaxDefinitionChanged object: self];
	
	[self recolorCompleteFile: self];
}


// -----------------------------------------------------------------------------
//	takeSyntaxDefinitionFilenameFromTagOf:
//		Menu action for our menu items that allow changing the syntax definition
//		to use.
//
//	REVISIONS:
//		2004-05-18	witness	Created.
// -----------------------------------------------------------------------------

-(IBAction) takeSyntaxDefinitionFilenameFromTagOf: (id)sender
{
	[self setSyntaxDefinitionFilename: [sUKMSCTDSyntaxDefinitionFiles objectAtIndex: [sender tag]]];
}


// -----------------------------------------------------------------------------
//	validateMenuItem:
//		Make sure the menu item for the syntax coloring scheme this file uses
//		is selectable and checked.
//
//	REVISIONS:
//		2004-05-18	witness	Created.
// -----------------------------------------------------------------------------

-(BOOL) validateMenuItem: (NSMenuItem*)anItem
{
	if( [anItem action] == @selector(takeSyntaxDefinitionFilenameFromTagOf:) )
	{
		[anItem setState: ([[sUKMSCTDSyntaxDefinitionFiles objectAtIndex: [anItem tag]] isEqualToString: [self syntaxDefinitionFilename]])];
		
		return( [anItem tag] < [sUKMSCTDSyntaxDefinitionFiles count] );
	}
	else
		return [super validateMenuItem: anItem];
}


// -----------------------------------------------------------------------------
//	windowNibName:
//		By default, UKMultiSyntaxColoredTextDocument uses a different NIB which
//		includes a popup menu in the status bar. If you want the menu in the
//		main menu bar instead, just subclass this and override this method to
//		return [super windowNibName], which gets you the regular NIB from the
//		superclass without the popup, and it'll cause the code in here to look
//		for its menu in the menu bar because the syntaxDefinitionMenu outlet
//		won't be set. Of course you can also return any other NIB you create
//		here, though then it'll be your duty to keep it in sync with the
//		"official" ones from me.
//
//	REVISIONS:
//		2004-05-18	witness	Created.
// -----------------------------------------------------------------------------

-(NSString*)	windowNibName
{
    return @"UKMultiSyntaxColoredTextDocument";
}


@end
