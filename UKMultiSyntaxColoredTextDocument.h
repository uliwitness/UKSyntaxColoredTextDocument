//
//  UKMultiSyntaxColoredTextDocument.h
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

/*
	This is a variant of UKSyntaxColoredTextDocument that allows switching between
	different syntax definitions. Syntax definitions go into a "Syntax Definitions"
	folder (either in your Bundle's Resources folder, in the user's Application
	Support folder, or in the Computer's Application Support folder).
	
	Create a submenu or menu somewhere in which you put one menu item whose action
	is takeSyntaxDefinitionFilenameFromTagOf: and whose target is the first responder.
	UKMultiSyntaxColoredTextDocument will remove that menu item and replace it with
	a list of the syntax definitions in those three folders. Right now this menu
	item must be at the bottom of the menu, or the only one in the menu.
	
	You can also use a popup menu in the window instead and hook it up to the
	syntaxDefinitionMenu outlet (like UKMultiSyntaxColoredTextDocument.nib does
	it) to have it populated instead of the main menu.
*/


// -----------------------------------------------------------------------------
//	Headers:
// -----------------------------------------------------------------------------

#import "UKSyntaxColoredTextDocument.h"


// -----------------------------------------------------------------------------
//	Constants:
// -----------------------------------------------------------------------------

// Define UKSCTD_APPLICATION_NAME to be an NSString containing your app's name
//  in your prefix header to make sure the subfolder of "Application Support"
//  where UKSCTD will look for the "Syntax Definitions" folder is the right one.
//  If the constant isn't defined, this will simply choose the display name of
//  the application, which will be the right thing until one of your users
//  decides to rename the application. :-S

#ifndef UKSCTD_APPLICATION_NAME
#define UKSCTD_APPLICATION_NAME [[NSFileManager defaultManager] displayNameAtPath: [[NSBundle mainBundle] bundlePath]]
#warning Please define UKSCTD_APPLICATION_NAME to be a constant NSString containing your app name, so users can rename your application without ill results.
#endif


// -----------------------------------------------------------------------------
//	Class:
// -----------------------------------------------------------------------------

@interface UKMultiSyntaxColoredTextDocument : UKSyntaxColoredTextDocument
{
	NSString*				syntaxDefinitionFilename;   // Name of currently selected syntax definition.
	IBOutlet NSMenu*		syntaxDefinitionMenu;		// If you use a popup menu, connect its menu to this outlet.
}

@property (nonatomic, copy) NSString *syntaxDefinitionFilename;

-(IBAction)		takeSyntaxDefinitionFilenameFromTagOf: (id)sender;  // Menu action!

// Private:
-(void) addSyntaxFilesFromFolderToArray: (NSString*)fpath;
-(void) reloadSyntaxDefinitionFiles;
-(void) rebuildSyntaxMenu;

@end


// -----------------------------------------------------------------------------
//	Notifications:
// -----------------------------------------------------------------------------

extern NSString*	UKMultiSyntaxColoredTextDocumentSyntaxDefinitionChanged;
