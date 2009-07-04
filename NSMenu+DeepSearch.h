//
//  NSMenu+DeepSearch.h
//  UKSyntaxColoredDocument
//
//  Created by Uli Kusterer on Tue May 18 2004.
//  Copyright (c) 2004 M. Uli Kusterer. All rights reserved.
//

/*
	This category adds a method to NSMenu that lets you perform a deep search
	in a menu for an item with a particular target and action. This is e.g.
	very handy when you're looking for an item and don't know what menu it is
	in. Simply pass [NSApp mainMenu] as the menu, and get back the menu item,
	which knows what menu it belongs to.
*/

// -----------------------------------------------------------------------------
//	Headers:
// -----------------------------------------------------------------------------

#import <Foundation/Foundation.h>


// -----------------------------------------------------------------------------
//	Interface:
// -----------------------------------------------------------------------------

@interface NSMenu (DeepSearch)

// Perform a deep search on a menu and its submenus: (returns NIL if the item couldn't be found)
-(id <NSMenuItem>)  findItemWithTarget: (id)targ andAction: (SEL)action;

@end
