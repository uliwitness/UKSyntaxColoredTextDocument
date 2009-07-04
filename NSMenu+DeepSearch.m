//
//  NSMenu+DeepSearch.m
//  UKSyntaxColoredDocument
//
//  Created by Uli Kusterer on Tue May 18 2004.
//  Copyright (c) 2004 M. Uli Kusterer. All rights reserved.
//

// -----------------------------------------------------------------------------
//	Headers:
// -----------------------------------------------------------------------------

#import "NSMenu+DeepSearch.h"


@implementation NSMenu (DeepSearch)

// -----------------------------------------------------------------------------
//	findItemWithTarget:andAction:
//		Calls indexOfItemWithTarget:andAction: on the menu, and if it doesn't
//		find an item, calls itself recursively on the submenus of all items
//		in the specified menu.
//
//  REVISIONS:
//		2004-05-18  witness Created.
// -----------------------------------------------------------------------------

-(id <NSMenuItem>)  findItemWithTarget: (id)targ andAction: (SEL)action
{
	// Look in this menu:
	int itemIndex = [self indexOfItemWithTarget: targ andAction: action];
	if( itemIndex >= 0 )
		return [self itemAtIndex: itemIndex];   // Return the item we found in this menu.
	
	// If not found, search our items' submenus:
	NSArray*		items = [self itemArray];
	NSEnumerator*   enny = [items objectEnumerator];
	id<NSMenuItem>	currItem = nil;
	
	while( (currItem = [enny nextObject]) )
	{
		if( [currItem hasSubmenu] )
		{
			currItem = [[currItem submenu] findItemWithTarget: targ andAction: action]; // Recurse deeper.
			if( currItem )
				return currItem;	// Found, exit & return item from submenu.
		}
	}
	
	// Nothing found? Report failure:
	return nil;
}

@end
