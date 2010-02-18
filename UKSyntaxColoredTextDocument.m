/* =============================================================================
	FILE:		UKSyntaxColoredTextDocument.m
	PROJECT:	CocoaTads
	
	AUTHORS:	M. Uli Kusterer <witness@zathras.de>, (c) 2003, all rights
				reserved.
	
	REVISIONS:
		2003-05-31	UK	Created.
   ========================================================================== */

#import "UKSyntaxColoredTextDocument.h"
#import "NSArray+Color.h"
#import "NSScanner+SkipUpToCharset.h"


static BOOL			sSyntaxColoredTextDocPrefsInited = NO;


@implementation UKSyntaxColoredTextDocument


/* -----------------------------------------------------------------------------
	init:
		Constructor that inits sourceCode member variable as a flag. It's
		storage for the text until the NIB's been loaded.
   -------------------------------------------------------------------------- */

-(id)	init
{
    self = [super init];
    if (self)
	{
		sourceCode = nil;
		autoSyntaxColoring = YES;
		maintainIndentation = YES;
		recolorTimer = nil;
		syntaxColoringBusy = NO;
	}
    return self;
}


-(void)	dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	[sourceCode release];
	sourceCode = nil;
	[recolorTimer invalidate];
	[recolorTimer release];
	recolorTimer = nil;
	[replacementString release];
	replacementString = nil;
	
	[super dealloc];
}


/* -----------------------------------------------------------------------------
	windowNibName:
		Name of NIB file to use.
   -------------------------------------------------------------------------- */

-(NSString*)	windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"UKSyntaxColoredTextDocument";
}


+(void) makeSurePrefsAreInited
{
	if( !sSyntaxColoredTextDocPrefsInited )
	{
		NSUserDefaults*	prefs = [NSUserDefaults standardUserDefaults];
		[prefs registerDefaults: [NSDictionary dictionaryWithContentsOfFile: [[NSBundle mainBundle] pathForResource: @"SyntaxColorDefaults" ofType: @"plist"]]];

		sSyntaxColoredTextDocPrefsInited = YES;
	}
}


/* -----------------------------------------------------------------------------
	windowControllerDidLoadNib:
		NIB has been loaded, fill the text view with our text and apply
		initial syntax coloring.
   -------------------------------------------------------------------------- */

-(void)	windowControllerDidLoadNib: (NSWindowController*)aController
{
    [super windowControllerDidLoadNib:aController];
	
	// Set up some sensible defaults for syntax coloring:
	[[self class] makeSurePrefsAreInited];
	
	// Load source code into text view, if necessary:
	if( sourceCode != nil )
	{
		[textView setString: sourceCode];
		[sourceCode release];
		sourceCode = nil;
	}
	
	// Set up our progress indicator:
	[progress setStyle: NSProgressIndicatorSpinningStyle];	// NIB forgets that :-(
	[progress setDisplayedWhenStopped:NO];
	[progress setUsesThreadedAnimation:YES];
	
	[status setStringValue: @"Finished."];
	
	// Register for "text changed" notifications of our text storage:
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processEditing:)
					name: NSTextStorageDidProcessEditingNotification
					object: [textView textStorage]];
	
	// Put selection at top like Project Builder has it, so user sees it:
	[textView setSelectedRange: NSMakeRange(0,0)];

	// Make sure text isn't wrapped:
	[self turnOffWrapping];
	
	// Do initial syntax coloring of our file:
	[self recolorCompleteFile:nil];
	
	// Make sure we can use "find" if we're on 10.3:
	if( [textView respondsToSelector: @selector(setUsesFindPanel:)] )
		[textView setUsesFindPanel: YES];
}

/* -----------------------------------------------------------------------------
	dataRepresentationOfType:
		Save raw text to a file as MacRoman text.
   -------------------------------------------------------------------------- */

-(NSData*)	dataRepresentationOfType: (NSString*)aType
{
    return [[textView string] dataUsingEncoding: NSMacOSRomanStringEncoding allowLossyConversion:YES];
}

/* -----------------------------------------------------------------------------
	loadDataRepresentation:
		Load plain MacRoman text from a text file.
   -------------------------------------------------------------------------- */

-(BOOL)	loadDataRepresentation: (NSData*)data ofType: (NSString*)aType
{
	// sourceCode is a member variable:
	if( sourceCode )
	{
		[sourceCode release];   // Release any old text.
		sourceCode = nil;
	}
	sourceCode = [[NSString alloc] initWithData:data encoding: NSMacOSRomanStringEncoding]; // Load the new text.
	
	/* Try to load it into textView and syntax colorize it:
		Since this may be called before the NIB has been loaded, we keep around
		sourceCode as a data member and try these two calls again in windowControllerDidLoadNib: */
	[textView setString: sourceCode];
	[self recolorCompleteFile:nil];

	// Try to get selection info if possible:
	NSAppleEventDescriptor*  evt = [[NSAppleEventManager sharedAppleEventManager] currentAppleEvent];
	if( evt )
	{
		NSAppleEventDescriptor*  param = [evt paramDescriptorForKeyword: keyAEPosition];
		if( param )		// This is always false when xCode calls us???
		{
			NSData*					data = [param data];
			struct SelectionRange   range;
			
			memmove( &range, [data bytes], sizeof(range) );
			
			if( range.lineNum >= 0 )
				[self goToLine: range.lineNum +1];
			else
				[self goToRangeFrom: range.startRange toChar: range.endRange];
		}
	}
	
	return YES;
}


/* -----------------------------------------------------------------------------
	processEditing:
		Part of the text was changed. Recolor it.
   -------------------------------------------------------------------------- */

-(void) processEditing: (NSNotification*)notification
{
    NSTextStorage	*textStorage = [notification object];
	NSRange			range = [textStorage editedRange];
	int				changeInLen = [textStorage changeInLength];
	BOOL			wasInUndoRedo = [[self undoManager] isUndoing] || [[self undoManager] isRedoing];
	BOOL			textLengthMayHaveChanged = NO;
	
	// Was delete op or undo that could have changed text length?
	if( wasInUndoRedo )
	{
		textLengthMayHaveChanged = YES;
		range = [textView selectedRange];
	}
	if( changeInLen <= 0 )
		textLengthMayHaveChanged = YES;
	
	//	Try to get chars around this to recolor any identifier we're in:
	if( textLengthMayHaveChanged )
	{
		if( range.location > 0 )
			range.location--;
		if( (range.location +range.length +2) < [textStorage length] )
			range.length += 2;
		else if( (range.location +range.length +1) < [textStorage length] )
			range.length += 1;
	}
	
	NSRange						currRange = range;
    
	// Perform the syntax coloring:
	if( autoSyntaxColoring && range.length > 0 )
	{
		NSRange			effectiveRange;
		NSString*		rangeMode;
		
		
		rangeMode = [textStorage attribute: TD_SYNTAX_COLORING_MODE_ATTR
								atIndex: currRange.location
								effectiveRange: &effectiveRange];
		
		unsigned int		x = range.location;
		
		/* TODO: If we're in a multi-line comment and we're typing a comment-end
			character, or we're in a string and we're typing a quote character,
			this should include the rest of the text up to the next comment/string
			end character in the recalc. */
		
		// Scan up to prev line break:
		while( x > 0 )
		{
			unichar theCh = [[textStorage string] characterAtIndex: x];
			if( theCh == '\n' || theCh == '\r' )
				break;
			--x;
		}
		
		currRange.location = x;
		
		// Scan up to next line break:
		x = range.location +range.length;
		
		while( x < [textStorage length] )
		{
			unichar theCh = [[textStorage string] characterAtIndex: x];
			if( theCh == '\n' || theCh == '\r' )
				break;
			++x;
		}
		
		currRange.length = x -currRange.location;
		
		// Open identifier, comment etc.? Make sure we include the whole range.
		if( rangeMode != nil )
			currRange = NSUnionRange( currRange, effectiveRange );
		
		// Actually recolor the changed part:
		[self recolorRange: currRange];
	}
}


/* -----------------------------------------------------------------------------
	textView:shouldChangeTextinRange:replacementString:
		Perform indentation-maintaining if we're supposed to.
   -------------------------------------------------------------------------- */

-(BOOL) textView:(NSTextView *)tv shouldChangeTextInRange:(NSRange)afcr replacementString:(NSString *)rps
{
	if( maintainIndentation )
	{
		affectedCharRange = afcr;
		if( replacementString )
		{
			[replacementString release];
			replacementString = nil;
		}
		replacementString = [rps retain];
		
		[self performSelector: @selector(didChangeText) withObject: nil afterDelay: 0.0];	// Queue this up on the event loop. If we change the text here, we only confuse the undo stack.
	}
	
	return YES;
}


-(void)	didChangeText	// This actually does what we want to do in textView:shouldChangeTextInRange:
{
	if( maintainIndentation && replacementString && ([replacementString isEqualToString:@"\n"]
		|| [replacementString isEqualToString:@"\r"]) )
	{
		NSMutableAttributedString*  textStore = [textView textStorage];
		BOOL						hadSpaces = NO;
		unsigned int				lastSpace = affectedCharRange.location,
									prevLineBreak = 0;
		NSRange						spacesRange = { 0, 0 };
		unichar						theChar = 0;
		unsigned int				x = (affectedCharRange.location == 0) ? 0 : affectedCharRange.location -1;
		NSString*					tsString = [textStore string];
		
		while( true )
		{
			if( x > ([tsString length] -1) )
				break;
			
			theChar = [tsString characterAtIndex: x];
			
			switch( theChar )
			{
				case '\n':
				case '\r':
					prevLineBreak = x +1;
					x = 0;  // Terminate the loop.
					break;
				
				case ' ':
				case '\t':
					if( !hadSpaces )
					{
						lastSpace = x;
						hadSpaces = YES;
					}
					break;
				
				default:
					hadSpaces = NO;
					break;
			}
			
			if( x == 0 )
				break;
			
			x--;
		}
		
		if( hadSpaces )
		{
			spacesRange.location = prevLineBreak;
			spacesRange.length = lastSpace -prevLineBreak +1;
			if( spacesRange.length > 0 )
				[textView insertText: [tsString substringWithRange:spacesRange]];
		}
	}
}


/* -----------------------------------------------------------------------------
	toggleAutoSyntaxColoring:
		Action for menu item that toggles automatic syntax coloring on and off.
   -------------------------------------------------------------------------- */

-(IBAction)	toggleAutoSyntaxColoring: (id)sender
{
	[self setAutoSyntaxColoring: ![self autoSyntaxColoring]];
	[self recolorCompleteFile: nil];
}


/* -----------------------------------------------------------------------------
	setAutoSyntaxColoring:
		Accessor to turn automatic syntax coloring on or off.
   -------------------------------------------------------------------------- */

-(void)		setAutoSyntaxColoring: (BOOL)state
{
	autoSyntaxColoring = state;
}

/* -----------------------------------------------------------------------------
	autoSyntaxColoring:
		Accessor for determining whether automatic syntax coloring is on or off.
   -------------------------------------------------------------------------- */

-(BOOL)		autoSyntaxColoring
{
	return autoSyntaxColoring;
}


/* -----------------------------------------------------------------------------
	toggleMaintainIndentation:
		Action for menu item that toggles indentation maintaining on and off.
   -------------------------------------------------------------------------- */

-(IBAction)	toggleMaintainIndentation: (id)sender
{
	[self setMaintainIndentation: ![self maintainIndentation]];
}


/* -----------------------------------------------------------------------------
	setMaintainIndentation:
		Accessor to turn indentation maintaining on or off.
   -------------------------------------------------------------------------- */

-(void)		setMaintainIndentation: (BOOL)state
{
	maintainIndentation = state;
}

/* -----------------------------------------------------------------------------
	maintainIndentation:
		Accessor for determining whether indentation maintaining is on or off.
   -------------------------------------------------------------------------- */

-(BOOL)		maintainIndentation
{
	return maintainIndentation;
}



/* -----------------------------------------------------------------------------
	showGoToPanel:
		Action for menu item that shows the "Go to line" panel.
   -------------------------------------------------------------------------- */

-(IBAction) showGoToPanel: (id)sender
{
	[gotoPanel showGoToSheet: [self windowForSheet]];
}


/* -----------------------------------------------------------------------------
	goToLine:
		This selects the specified line of the document.
   -------------------------------------------------------------------------- */

-(void)	goToLine: (int)lineNum
{
	NSRange			theRange = { 0, 0 };
	NSString*		vString = [textView string];
	unsigned		currLine = 1;
	NSCharacterSet* vSet = [NSCharacterSet characterSetWithCharactersInString: @"\n\r"];
	unsigned		x;
	unsigned		lastBreakOffs = 0;
	unichar			lastBreakChar = 0;
	
	for( x = 0; x < [vString length]; x++ )
	{
		unichar		theCh = [vString characterAtIndex: x];
		
		// Skip non-linebreak chars:
		if( ![vSet characterIsMember: theCh] )
			continue;
		
		// If this is the LF in a CRLF sequence, only count it as one line break:
		if( theCh == '\n' && lastBreakOffs == (x-1)
			&& lastBreakChar == '\r' )
		{
			lastBreakOffs = 0;
			lastBreakChar = 0;
			theRange.location++;
			continue;
		}
		
		// Calc range and increase line number:
		theRange.length = x -theRange.location +1;
		if( currLine >= lineNum )
			break;
		currLine++;
		theRange.location = theRange.location +theRange.length;
		lastBreakOffs = x;
		lastBreakChar = theCh;
	}
	
	[status setStringValue: [NSString stringWithFormat: @"Characters %u to %u", theRange.location +1, theRange.location +theRange.length]];
	[textView scrollRangeToVisible: theRange];
	[textView setSelectedRange: theRange];
}


/* -----------------------------------------------------------------------------
	turnOffWrapping:
		Makes the view so wide that text won't wrap anymore.
   -------------------------------------------------------------------------- */

-(void) turnOffWrapping
{
	const float			LargeNumberForText = 1.0e7;
	NSTextContainer*	textContainer = [textView textContainer];
	NSRect				frame;
	NSScrollView*		scrollView = [textView enclosingScrollView];
	
	// Make sure we can see right edge of line:
    [scrollView setHasHorizontalScroller:YES];
	
	// Make text container so wide it won't wrap:
	[textContainer setContainerSize: NSMakeSize(LargeNumberForText, LargeNumberForText)];
	[textContainer setWidthTracksTextView:NO];
    [textContainer setHeightTracksTextView:NO];

	// Make sure text view is wide enough:
	frame.origin = NSMakePoint(0.0, 0.0);
    frame.size = [scrollView contentSize];
	
    [textView setMaxSize:NSMakeSize(LargeNumberForText, LargeNumberForText)];
    [textView setHorizontallyResizable:YES];
    [textView setVerticallyResizable:YES];
    [textView setAutoresizingMask:NSViewNotSizable];
}


/* -----------------------------------------------------------------------------
	goToCharacter:
		This selects the specified character in the document.
   -------------------------------------------------------------------------- */

-(void)	goToCharacter: (int)charNum
{
	[self goToRangeFrom: charNum toChar: charNum +1];
}


-(void) goToRangeFrom: (int)startCh toChar: (int)endCh
{
	NSRange		theRange = { 0, 0 };

	theRange.location = startCh -1;
	theRange.length = endCh -startCh;
	
	if( startCh == 0 || startCh > [[textView string] length] )
		return;
	
	[status setStringValue: [NSString stringWithFormat: @"Characters %u to %u",
								theRange.location +1, theRange.location +theRange.length]];
	[textView scrollRangeToVisible: theRange];
	[textView setSelectedRange: theRange];
}


-(IBAction) indentSelection: (id)sender
{
	[[self undoManager] registerUndoWithTarget: self selector: @selector(unindentSelection:) object: nil];
	
	NSRange				selRange = [textView selectedRange],
						nuSelRange = selRange;
	unsigned			x;
	NSMutableString*	str = [[textView textStorage] mutableString];
	
	// Unselect any trailing returns so we don't indent the next line after a full-line selection.
	if( selRange.length > 1 && ([str characterAtIndex: selRange.location +selRange.length -1] == '\n'
		|| [str characterAtIndex: selRange.location +selRange.length -1] == '\r') )
		selRange.length--;
	
	for( x = selRange.location +selRange.length -1; x >= selRange.location; x-- )
	{
		if( [str characterAtIndex: x] == '\n'
			|| [str characterAtIndex: x] == '\r' )
		{
			[str insertString: @"\t" atIndex: x+1];
			nuSelRange.length++;
		}
		
		if( x == 0 )
			break;
	}
	
	[str insertString: @"\t" atIndex: nuSelRange.location];
	nuSelRange.length++;
	[textView setSelectedRange: nuSelRange];
}


-(IBAction) unindentSelection: (id)sender
{
	NSRange				selRange = [textView selectedRange],
						nuSelRange = selRange;
	unsigned			x, n;
	unsigned			lastIndex = selRange.location +selRange.length -1;
	NSMutableString*	str = [[textView textStorage] mutableString];
	
	// Unselect any trailing returns so we don't indent the next line after a full-line selection.
	if( selRange.length > 1 && ([str characterAtIndex: selRange.location +selRange.length -1] == '\n'
		|| [str characterAtIndex: selRange.location +selRange.length -1] == '\r') )
		selRange.length--;
	
	if( selRange.length == 0 )
		return;
	
	[[self undoManager] registerUndoWithTarget: self selector: @selector(indentSelection:) object: nil];
	
	for( x = lastIndex; x >= selRange.location; x-- )
	{
		if( [str characterAtIndex: x] == '\n'
			|| [str characterAtIndex: x] == '\r' )
		{
			if( (x +1) <= lastIndex)
			{
				if( [str characterAtIndex: x+1] == '\t' )
				{
					[str deleteCharactersInRange: NSMakeRange(x+1,1)];
					nuSelRange.length--;
				}
				else
				{
					for( n = x+1; (n <= (x+4)) && (n <= lastIndex); n++ )
					{
						if( [str characterAtIndex: x+1] != ' ' )
							break;
						[str deleteCharactersInRange: NSMakeRange(x+1,1)];
						nuSelRange.length--;
					}
				}
			}
		}
		
		if( x == 0 )
			break;
	}
	
	if( [str characterAtIndex: nuSelRange.location] == '\t' )
	{
		[str deleteCharactersInRange: NSMakeRange(nuSelRange.location,1)];
		nuSelRange.length--;
	}
	else
	{
		for( n = 1; (n <= 4) && (n <= lastIndex); n++ )
		{
			if( [str characterAtIndex: nuSelRange.location] != ' ' )
				break;
			[str deleteCharactersInRange: NSMakeRange(nuSelRange.location,1)];
			nuSelRange.length--;
		}
	}
	
	[textView setSelectedRange: nuSelRange];
}


/* -----------------------------------------------------------------------------
	toggleCommentForSelection:
		Add a comment to the start of this line/remove an existing comment.
   -------------------------------------------------------------------------- */

-(IBAction)	toggleCommentForSelection: (id)sender
{
	[[self undoManager] registerUndoWithTarget: self selector: @selector(toggleCommentForSelection:) object: nil];
	
	NSRange				selRange = [textView selectedRange];
	unsigned			x;
	NSMutableString*	str = [[textView textStorage] mutableString];
	
	if( selRange.length == 0 )
		selRange.length++;
	
//	NSLog(@"selection %d,%d", selRange.location, selRange.length);
	
	// Are we at the end of a line?
	if ([str characterAtIndex:selRange.location] == '\n' ||
			[str characterAtIndex:selRange.location] == '\r') 
	{
		if( selRange.location > 0 )
		{
			selRange.location--;
			selRange.length++;
		}
	}
	
	// Move the selection to the start of a line
	while (selRange.location >= 0)
	{
//		NSLog(@"Checking charater %c", [str characterAtIndex:selRange.location]);
		if ([str characterAtIndex:selRange.location] == '\n' || [str characterAtIndex:selRange.location] == '\r')
		{
			selRange.location++;
			selRange.length--;
			break;
		}
		selRange.location--;
		selRange.length++;
	}

	// Select up to the end of a line
	while ( (selRange.location+selRange.length-1) < [str length]  &&
				 !([str characterAtIndex:selRange.location+selRange.length-1] == '\n' ||
					 [str characterAtIndex:selRange.location+selRange.length-1] == '\r')) 
	{
		selRange.length++;
	}
	
	if (selRange.length == 0)
		return;
	
	// Unselect any trailing returns so we don't indent the next line after a full-line selection.
	while([str characterAtIndex:selRange.location+selRange.length-1] == '\n' ||
				[str characterAtIndex:selRange.location+selRange.length-1] == '\r')
	{
		selRange.length--;
	}
	
	
//	NSLog(@"Selected range: '%@'", [str substringWithRange:selRange]);
	NSRange nuSelRange = selRange;
	
	for( x = selRange.location +selRange.length -1; x >= selRange.location; x-- )
	{
		if( [str characterAtIndex: x] == '\n'
			 || [str characterAtIndex: x] == '\r' )
		{
//			NSLog(@"Checking char %c", [str characterAtIndex:x+1]);
			if( [str characterAtIndex:x+1] == '%' )
			{
				[str deleteCharactersInRange:NSMakeRange(x+1, 1)];
				nuSelRange.length--;
			}
			else
			{
				[str insertString: @"%" atIndex: x+1];
				nuSelRange.length++;
			}
		}
		
		if( x == 0 )
			break;
	}
	
	if( [str characterAtIndex:nuSelRange.location] == '%' )
	{
		[str deleteCharactersInRange:NSMakeRange( nuSelRange.location, 1 )];
		nuSelRange.length--;
	}
	else
	{		
		[str insertString: @"%" atIndex: nuSelRange.location];
		nuSelRange.length++;
	}
	[textView setSelectedRange: nuSelRange];
}


/* -----------------------------------------------------------------------------
	validateMenuItem:
		Make sure check marks of the "Toggle auto syntax coloring" and "Maintain
		indentation" menu items are set up properly.
   -------------------------------------------------------------------------- */

-(BOOL)	validateMenuItem:(NSMenuItem*)menuItem
{
	if( [menuItem action] == @selector(toggleAutoSyntaxColoring:) )
	{
		[menuItem setState: [self autoSyntaxColoring]];
		return YES;
	}
	else if( [menuItem action] == @selector(toggleMaintainIndentation:) )
	{
		[menuItem setState: [self maintainIndentation]];
		return YES;
	}
	else
		return [super validateMenuItem: menuItem];
}


/* -----------------------------------------------------------------------------
	recolorCompleteFile:
		IBAction to do a complete recolor of the whole friggin' document.
		This is called once after the document's been loaded and leaves some
		custom styles in the document which are used by recolorRange to properly
		perform recoloring of parts.
   -------------------------------------------------------------------------- */

-(IBAction)	recolorCompleteFile: (id)sender
{
	if( sourceCode != nil && textView )
	{
		[textView setString: sourceCode]; // Causes recoloring notification.
		[sourceCode release];
		sourceCode = nil;
	}
	else
	{
		NSRange		range = NSMakeRange(0,[[textView textStorage] length]);
		[self recolorRange: range];
	}
}


/* -----------------------------------------------------------------------------
	recolorRange:
		Try to apply syntax coloring to the text in our text view. This
		overwrites any styles the text may have had before. This function
		guarantees that it'll preserve the selection.
		
		Note that the order in which the different things are colorized is
		important. E.g. identifiers go first, followed by comments, since that
		way colors are removed from identifiers inside a comment and replaced
		with the comment color, etc. 
		
		The range passed in here is special, and may not include partial
		identifiers or the end of a comment. Make sure you include the entire
		multi-line comment etc. or it'll lose color.
		
		This calls oldRecolorRange to handle old-style syntax definitions.
   -------------------------------------------------------------------------- */

-(void)		recolorRange: (NSRange)range
{
	if( syntaxColoringBusy )	// Prevent endless loop when recoloring's replacement of text causes processEditing to fire again.
		return;
	
	if( textView == nil || range.length == 0	// Don't like doing useless stuff.
		|| recolorTimer )						// And don't like recoloring partially if a full recolorization is pending.
		return;
	
	// Kludge fix for case where we sometimes exceed text length:ra
	int diff = [[textView textStorage] length] -(range.location +range.length);
	if( diff < 0 )
		range.length += diff;
	
	NS_DURING
		syntaxColoringBusy = YES;
		[progress startAnimation:nil];
		
		[status setStringValue: [NSString stringWithFormat: @"Recoloring syntax in %@", NSStringFromRange(range)]];
		
		// Get the text we'll be working with:
		NSRange						vOldSelection = [textView selectedRange];
		NSMutableAttributedString*	vString = [[NSMutableAttributedString alloc] initWithString: [[[textView textStorage] string] substringWithRange: range]];
		[vString autorelease];
		
		// Load colors and fonts to use from preferences:
		
		// Load our dictionary which contains info on coloring this language:
		NSDictionary*				vSyntaxDefinition = [self syntaxDefinitionDictionary];
		NSEnumerator*				vComponentsEnny = [[vSyntaxDefinition objectForKey: @"Components"] objectEnumerator];
		
		if( vComponentsEnny == nil )	// No new-style list of components to colorize? Use old code.
		{
			#if TD_BACKWARDS_COMPATIBLE
			syntaxColoringBusy = NO;
			[self oldRecolorRange: range];
			#endif
			NS_VOIDRETURN;
		}
		
		// Loop over all available components:
		NSDictionary*				vCurrComponent = nil;
		NSDictionary*				vStyles = [self defaultTextAttributes];
		NSUserDefaults*				vPrefs = [NSUserDefaults standardUserDefaults];

		while( (vCurrComponent = [vComponentsEnny nextObject]) )
		{
			NSString*   vComponentType = [vCurrComponent objectForKey: @"Type"];
			NSString*   vComponentName = [vCurrComponent objectForKey: @"Name"];
			NSString*   vColorKeyName = [@"SyntaxColoring:Color:" stringByAppendingString: vComponentName];
			NSColor*	vColor = [[vPrefs arrayForKey: vColorKeyName] colorValue];
			
			if( !vColor )
				vColor = [[vCurrComponent objectForKey: @"Color"] colorValue];
			
			if( [vComponentType isEqualToString: @"BlockComment"] )
			{
				[self colorCommentsFrom: [vCurrComponent objectForKey: @"Start"]
						to: [vCurrComponent objectForKey: @"End"] inString: vString
						withColor: vColor andMode: vComponentName];
			}
			else if( [vComponentType isEqualToString: @"OneLineComment"] )
			{
				[self colorOneLineComment: [vCurrComponent objectForKey: @"Start"]
						inString: vString withColor: vColor andMode: vComponentName];
			}
			else if( [vComponentType isEqualToString: @"String"] )
			{
				[self colorStringsFrom: [vCurrComponent objectForKey: @"Start"]
						to: [vCurrComponent objectForKey: @"End"]
						inString: vString withColor: vColor andMode: vComponentName
						andEscapeChar: [vCurrComponent objectForKey: @"EscapeChar"]]; 
			}
			else if( [vComponentType isEqualToString: @"Tag"] )
			{
				[self colorTagFrom: [vCurrComponent objectForKey: @"Start"]
						to: [vCurrComponent objectForKey: @"End"] inString: vString
						withColor: vColor andMode: vComponentName
						exceptIfMode: [vCurrComponent objectForKey: @"IgnoredComponent"]];
			}
			else if( [vComponentType isEqualToString: @"Keywords"] )
			{
				NSArray* vIdents = [vCurrComponent objectForKey: @"Keywords"];
				if( !vIdents )
					vIdents = [[NSUserDefaults standardUserDefaults] objectForKey: [@"SyntaxColoring:Keywords:" stringByAppendingString: vComponentName]];
				if( !vIdents && [vComponentName isEqualToString: @"UserIdentifiers"] )
					vIdents = [[NSUserDefaults standardUserDefaults] objectForKey: TD_USER_DEFINED_IDENTIFIERS];
				if( vIdents )
				{
					NSCharacterSet*		vIdentCharset = nil;
					NSString*			vCurrIdent = nil;
					NSString*			vCsStr = [vCurrComponent objectForKey: @"Charset"];
					if( vCsStr )
						vIdentCharset = [NSCharacterSet characterSetWithCharactersInString: vCsStr];
					
					NSEnumerator*	vItty = [vIdents objectEnumerator];
					while( vCurrIdent = [vItty nextObject] )
						[self colorIdentifier: vCurrIdent inString: vString withColor: vColor
									andMode: vComponentName charset: vIdentCharset];
				}
			}
		}
		
		// Replace the range with our recolored part:
		[vString addAttributes: vStyles range: NSMakeRange( 0, [vString length] )];
		[[textView textStorage] replaceCharactersInRange: range withAttributedString: vString];
		
		[progress stopAnimation:nil];
		syntaxColoringBusy = NO;
	NS_HANDLER
		syntaxColoringBusy = NO;
		[progress stopAnimation:nil];
		[localException raise];
	NS_ENDHANDLER
}


/* -----------------------------------------------------------------------------
	oldRecolorRange:
		Try to apply syntax coloring to the text in our text view. This
		overwrites any styles the text may have had before. This function
		guarantees that it'll preserve the selection.
		
		Note that the order in which the different things are colorized is
		important. E.g. identifiers go first, followed by comments, since that
		way colors are removed from identifiers inside a comment and replaced
		with the comment color, etc. 
		
		The range passed in here is special, and may not include partial
		identifiers or the end of a comment. Make sure you include the entire
		multi-line comment etc. or it'll lose color.
		
		TODO: Anybody have any bright ideas how to refactor this?
   -------------------------------------------------------------------------- */

#if TD_BACKWARDS_COMPATIBLE
-(void)		oldRecolorRange: (NSRange)range
{
	if( syntaxColoringBusy )	// Prevent endless loop when recoloring's replacement of text causes processEditing to fire again.
		return;
	
	if( textView == nil || range.length == 0	// Don't like doing useless stuff.
		|| recolorTimer )						// And don't like recoloring partially if a full recolorization is pending.
		return;
	
	NS_DURING
		syntaxColoringBusy = YES;
		[progress startAnimation:nil];
		
		[status setStringValue: [NSString stringWithFormat: @"Recoloring syntax in %@", NSStringFromRange(range)]];
		
		// Get the text we'll be working with:
		NSRange						vOldSelection = [textView selectedRange];
		NSMutableAttributedString*	vString = [[NSMutableAttributedString alloc] initWithString: [[[textView textStorage] string] substringWithRange: range]];
		[vString autorelease];
		
		// The following should probably be loaded from a dictionary in some file, to allow adaptation to various languages:
		NSDictionary*				vSyntaxDefinition = [self syntaxDefinitionDictionary];
		NSString*					vBlockCommentStart = [vSyntaxDefinition objectForKey: @"BlockComment:Start"];
		NSString*					vBlockCommentEnd = [vSyntaxDefinition objectForKey: @"BlockComment:End"];
		NSString*					vBlockComment2Start = [vSyntaxDefinition objectForKey: @"BlockComment2:Start"];
		NSString*					vBlockComment2End = [vSyntaxDefinition objectForKey: @"BlockComment2:End"];
		NSString*					vOneLineCommentStart = [vSyntaxDefinition objectForKey: @"OneLineComment:Start"];
		NSString*					vTagStart = [vSyntaxDefinition objectForKey: @"Tag:Start"];
		NSString*					vTagEnd = [vSyntaxDefinition objectForKey: @"Tag:End"];
		NSString*					vTagIgnoredStyle = [vSyntaxDefinition objectForKey: @"Tag:IgnoredStyle"];
		NSString*					vStringEscapeCharacter = [vSyntaxDefinition objectForKey: @"String:EscapeChar"];
		NSCharacterSet*				vIdentCharset = nil;
		NSString*					vCsStr = [vSyntaxDefinition objectForKey: @"Identifiers:Charset"];
		if( vCsStr )
			vIdentCharset = [NSCharacterSet characterSetWithCharactersInString: vCsStr];
		
		// Load colors and fonts to use from preferences:
		NSUserDefaults*				vPrefs = [NSUserDefaults standardUserDefaults];
		NSColor*					vPreprocessorColor = [[vPrefs arrayForKey: @"SyntaxColoring:Color:Preprocessor"] colorValue];
		NSColor*					vCommentColor = [[vPrefs arrayForKey: @"SyntaxColoring:Color:Comments"] colorValue];
		NSColor*					vComment2Color = [[vPrefs arrayForKey: @"SyntaxColoring:Color:Comments2"] colorValue];
		NSColor*					vStringColor = [[vPrefs arrayForKey: @"SyntaxColoring:Color:Strings"] colorValue];
		NSColor*					vIdentifierColor = [[vPrefs arrayForKey: @"SyntaxColoring:Color:Identifiers"] colorValue];
		NSColor*					vIdentifier2Color = [[vPrefs arrayForKey: @"SyntaxColoring:Color:Identifiers2"] colorValue];
		NSColor*					vTagColor = [[vPrefs arrayForKey: @"SyntaxColoring:Color:Tags"] colorValue];
		NSDictionary*				vStyles = [self defaultTextAttributes];
		
		// Color identifiers listed in "Identifiers" entry:
		NSString*		vCurrIdent;
		NSArray*		vIdents = [vSyntaxDefinition objectForKey: @"Identifiers"];
		if( vIdents )
		{
			NSEnumerator*	vItty = [vIdents objectEnumerator];
			while( vCurrIdent = [vItty nextObject] )
				[self colorIdentifier: vCurrIdent inString:vString withColor: vIdentifierColor
							andMode: TD_IDENTIFIER_ATTR charset: vIdentCharset];
		}
		
		// Color identifiers listed in "Identifiers2" entry:
		vIdents = [vSyntaxDefinition objectForKey: @"Identifiers2"];
		if( !vIdents )
			vIdents = [[NSUserDefaults standardUserDefaults] objectForKey: TD_USER_DEFINED_IDENTIFIERS];
		if( vIdents )
		{
			NSEnumerator*	vItty = [vIdents objectEnumerator];
			while( vCurrIdent = [vItty nextObject] )
				[self colorIdentifier: vCurrIdent inString:vString withColor: vIdentifier2Color
							andMode: TD_IDENTIFIER2_ATTR charset: vIdentCharset];
		}
		
		// Colorize comments, strings etc, obliterating any identifiers inside them:
		[self colorStringsFrom: @"\"" to: @"\"" inString: vString withColor: vStringColor andMode: TD_DOUBLE_QUOTED_STRING_ATTR andEscapeChar: vStringEscapeCharacter];   // Strings.
	
		// Colorize colorize any tags:
		if( vTagStart )
			[self colorTagFrom: vTagStart to: vTagEnd inString: vString withColor: vTagColor andMode: TD_TAG_ATTR exceptIfMode: vTagIgnoredStyle];
		
		// Preprocessor directives:
		if( vIdents )
		{
			vIdents = [vSyntaxDefinition objectForKey: @"PreprocessorDirectives"];
			NSEnumerator* vItty = [vIdents objectEnumerator];
			while( vCurrIdent = [vItty nextObject] )
				[self colorOneLineComment: vCurrIdent inString: vString withColor: vPreprocessorColor andMode: TD_PREPROCESSOR_ATTR];	// TODO Preprocessor directives should make sure they're at the start of a line, and that whitespace follows the directive.
		}
		
		// Comments:
		if( vOneLineCommentStart )
			[self colorOneLineComment: vOneLineCommentStart inString: vString withColor: vCommentColor andMode: TD_ONE_LINE_COMMENT_ATTR];
		if( vBlockCommentStart )
			[self colorCommentsFrom: vBlockCommentStart to: vBlockCommentEnd inString: vString withColor:vCommentColor andMode: TD_MULTI_LINE_COMMENT_ATTR];
		if( vBlockComment2Start )
			[self colorCommentsFrom: vBlockComment2Start to: vBlockComment2End inString: vString withColor:vComment2Color andMode: TD_MULTI_LINE_COMMENT2_ATTR];
		
		// Replace the range with our recolored part:
		[vString addAttributes: vStyles range: NSMakeRange( 0, [vString length] )];
		[[textView textStorage] replaceCharactersInRange: range withAttributedString: vString];
		
		NS_DURING
			[textView setSelectedRange:vOldSelection];  // Restore selection.
		NS_HANDLER
		NS_ENDHANDLER
	
		[progress stopAnimation:nil];
		syntaxColoringBusy = NO;
	NS_HANDLER
		syntaxColoringBusy = NO;
		[progress stopAnimation:nil];
		[localException raise];
	NS_ENDHANDLER
}
#endif


/* -----------------------------------------------------------------------------
	textView:willChangeSelectionFromCharacterRange:toCharacterRange:
		Delegate method called when our selection changes. Updates our status
		display to indicate which characters are selected.
   -------------------------------------------------------------------------- */

-(NSRange)  textView: (NSTextView*)theTextView willChangeSelectionFromCharacterRange: (NSRange)oldSelectedCharRange
					toCharacterRange:(NSRange)newSelectedCharRange
{
	unsigned		startCh = newSelectedCharRange.location +1,
					endCh = newSelectedCharRange.location +newSelectedCharRange.length;
	unsigned		lineNo = 1,
					lastLineStart = 0,
					x;
	unsigned		startChLine, endChLine;
	unichar			lastBreakChar = 0;
	unsigned		lastBreakOffs = 0;

	// Calc line number:
	for( x = 0; (x < startCh) && (x < [[theTextView string] length]); x++ )
	{
		unichar		theCh = [[theTextView string] characterAtIndex: x];
		switch( theCh )
		{
			case '\n':
				if( lastBreakOffs == (x-1) && lastBreakChar == '\r' )   // LF in CRLF sequence? Treat this as a single line break.
				{
					lastBreakOffs = 0;
					lastBreakChar = 0;
					continue;
				}
				// Else fall through!
				
			case '\r':
				lineNo++;
				lastLineStart = x +1;
				lastBreakOffs = x;
				lastBreakChar = theCh;
				break;
		}
	}
	
	startChLine = (newSelectedCharRange.location -lastLineStart) +1;
	endChLine = (newSelectedCharRange.location -lastLineStart) +newSelectedCharRange.length;
	
	NSImage*	img = nil;
	
	// Display info:
	if( startCh > endCh )   // Insertion mark!
	{
		img = [NSImage imageNamed: @"InsertionMark"];
		[status setStringValue: [NSString stringWithFormat: @"char %u, line %u (char %u in document)", startChLine, lineNo, startCh]];
	}
	else					// Selection
	{
		img = [NSImage imageNamed: @"SelectionRange"];
		[status setStringValue: [NSString stringWithFormat: @"char %u to %u, line %u (char %u to %u in document)", startChLine, endChLine, lineNo, startCh, endCh]];
	}
	
	[selectionKindImage setImage: img];
	
	return newSelectedCharRange;
}


/* -----------------------------------------------------------------------------
	syntaxDefinitionFilename:
		Like windowNibName, this should return the name of the syntax
		definition file to use. Advanced users may use this to allow different
		coloring to take place depending on the file extension by returning
		different file names here.
		
		Note that the ".plist" extension is automatically appended to the file
		name.
   -------------------------------------------------------------------------- */

-(NSString*)	syntaxDefinitionFilename
{
	return @"SyntaxDefinition";
}


/* -----------------------------------------------------------------------------
	syntaxDefinitionDictionary:
		This returns the syntax definition dictionary to use, which indicates
		what ranges of text to colorize. Advanced users may use this to allow
		different coloring to take place depending on the file extension by
		returning different dictionaries here.
		
		By default, this simply reads a dictionary from the .plist file
		indicated by -syntaxDefinitionFilename.
   -------------------------------------------------------------------------- */

-(NSDictionary*)	syntaxDefinitionDictionary
{
	return [NSDictionary dictionaryWithContentsOfFile: [[NSBundle mainBundle] pathForResource: [self syntaxDefinitionFilename] ofType:@"plist"]];
}


/* -----------------------------------------------------------------------------
	colorStringsFrom:
		Apply syntax coloring to all strings. This is basically the same code
		as used for multi-line comments, except that it ignores the end
		character if it is preceded by a backslash.
   -------------------------------------------------------------------------- */

-(void)	colorStringsFrom: (NSString*) startCh to: (NSString*) endCh inString: (NSMutableAttributedString*) s
							withColor: (NSColor*) col andMode:(NSString*)attr andEscapeChar: (NSString*)vStringEscapeCharacter
{
	NS_DURING
		NSScanner*					vScanner = [NSScanner scannerWithString: [s string]];
		NSDictionary*				vStyles = [NSDictionary dictionaryWithObjectsAndKeys:
													col, NSForegroundColorAttributeName,
													attr, TD_SYNTAX_COLORING_MODE_ATTR,
													nil];
		BOOL						vIsEndChar = NO;
		unichar						vEscChar = '\\';
		
		if( vStringEscapeCharacter )
		{
			if( [vStringEscapeCharacter length] != 0 )
				vEscChar = [vStringEscapeCharacter characterAtIndex: 0];
		}
		
		while( ![vScanner isAtEnd] )
		{
			int		vStartOffs,
					vEndOffs;
			vIsEndChar = NO;
			
			// Look for start of string:
			[vScanner scanUpToString: startCh intoString: nil];
			vStartOffs = [vScanner scanLocation];
			if( ![vScanner scanString:startCh intoString:nil] )
				NS_VOIDRETURN;

			while( !vIsEndChar && ![vScanner isAtEnd] )	// Loop until we find end-of-string marker or our text to color is finished:
			{
				[vScanner scanUpToString: endCh intoString: nil];
				if( ([vStringEscapeCharacter length] == 0) || [[s string] characterAtIndex: ([vScanner scanLocation] -1)] != vEscChar )	// Backslash before the end marker? That means ignore the end marker.
					vIsEndChar = YES;	// A real one! Terminate loop.
				if( ![vScanner scanString:endCh intoString:nil] )	// But skip this char before that.
					NS_VOIDRETURN;
				
				[progress animate:nil];
			}
			
			vEndOffs = [vScanner scanLocation];
			
			// Now mess with the string's styles:
			[s setAttributes: vStyles range: NSMakeRange( vStartOffs, vEndOffs -vStartOffs )];
		}
	NS_HANDLER
		// Just ignore it, syntax coloring isn't that important.
	NS_ENDHANDLER
}


/* -----------------------------------------------------------------------------
	colorCommentsFrom:
		Colorize block-comments in the text view.
	
	REVISIONS:
		2004-05-18  witness Documented.
   -------------------------------------------------------------------------- */

-(void)	colorCommentsFrom: (NSString*) startCh to: (NSString*) endCh inString: (NSMutableAttributedString*) s
							withColor: (NSColor*) col andMode:(NSString*)attr
{
	NS_DURING
		NSScanner*					vScanner = [NSScanner scannerWithString: [s string]];
		NSDictionary*				vStyles = [NSDictionary dictionaryWithObjectsAndKeys:
													col, NSForegroundColorAttributeName,
													attr, TD_SYNTAX_COLORING_MODE_ATTR,
													nil];
		
		while( ![vScanner isAtEnd] )
		{
			int		vStartOffs,
					vEndOffs;
			
			// Look for start of multi-line comment:
			[vScanner scanUpToString: startCh intoString: nil];
			vStartOffs = [vScanner scanLocation];
			if( ![vScanner scanString:startCh intoString:nil] )
				NS_VOIDRETURN;

			// Look for associated end-of-comment marker:
			[vScanner scanUpToString: endCh intoString: nil];
			if( ![vScanner scanString:endCh intoString:nil] )
				/*NS_VOIDRETURN*/;  // Don't exit. If user forgot trailing marker, indicate this by "bleeding" until end of string.
			vEndOffs = [vScanner scanLocation];
			
			// Now mess with the string's styles:
			[s setAttributes: vStyles range: NSMakeRange( vStartOffs, vEndOffs -vStartOffs )];
				
			[progress animate:nil];
		}
	NS_HANDLER
		// Just ignore it, syntax coloring isn't that important.
	NS_ENDHANDLER
}


/* -----------------------------------------------------------------------------
	colorOneLineComment:
		Colorize one-line-comments in the text view.
	
	REVISIONS:
		2004-05-18  witness Documented.
   -------------------------------------------------------------------------- */

-(void)	colorOneLineComment: (NSString*) startCh inString: (NSMutableAttributedString*) s
				withColor: (NSColor*) col andMode:(NSString*)attr
{
	NS_DURING
		NSScanner*					vScanner = [NSScanner scannerWithString: [s string]];
		NSDictionary*				vStyles = [NSDictionary dictionaryWithObjectsAndKeys:
													col, NSForegroundColorAttributeName,
													attr, TD_SYNTAX_COLORING_MODE_ATTR,
													nil];
		
		while( ![vScanner isAtEnd] )
		{
			int		vStartOffs,
					vEndOffs;
			
			// Look for start of one-line comment:
			[vScanner scanUpToString: startCh intoString: nil];
			vStartOffs = [vScanner scanLocation];
			if( ![vScanner scanString:startCh intoString:nil] )
				NS_VOIDRETURN;

			// Look for associated line break:
			if( ![vScanner skipUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString: @"\n\r"]] )
				;
			
			vEndOffs = [vScanner scanLocation];
			
			// Now mess with the string's styles:
			[s setAttributes: vStyles range: NSMakeRange( vStartOffs, vEndOffs -vStartOffs )];
				
			[progress animate:nil];
		}
	NS_HANDLER
		// Just ignore it, syntax coloring isn't that important.
	NS_ENDHANDLER
}


/* -----------------------------------------------------------------------------
	colorIdentifier:
		Colorize keywords in the text view.
	
	REVISIONS:
		2004-05-18  witness Documented.
   -------------------------------------------------------------------------- */

-(void)	colorIdentifier: (NSString*) ident inString: (NSMutableAttributedString*) s
			withColor: (NSColor*) col andMode:(NSString*)attr charset: (NSCharacterSet*)cset
{
	NS_DURING
		NSScanner*					vScanner = [NSScanner scannerWithString: [s string]];
		NSDictionary*				vStyles = [NSDictionary dictionaryWithObjectsAndKeys:
													col, NSForegroundColorAttributeName,
													attr, TD_SYNTAX_COLORING_MODE_ATTR,
													nil];
		int							vStartOffs = 0;
		
		// Skip any leading whitespace chars, somehow NSScanner doesn't do that:
		if( cset )
		{
			while( vStartOffs < [[s string] length] )
			{
				if( [cset characterIsMember: [[s string] characterAtIndex: vStartOffs]] )
					break;
				vStartOffs++;
			}
		}
		
		[vScanner setScanLocation: vStartOffs];
		
		while( ![vScanner isAtEnd] )
		{
			// Look for start of identifier:
			[vScanner scanUpToString: ident intoString: nil];
			vStartOffs = [vScanner scanLocation];
			if( ![vScanner scanString:ident intoString:nil] )
				NS_VOIDRETURN;
			
			if( vStartOffs > 0 )	// Check that we're not in the middle of an identifier:
			{
				// Alphanum character before identifier start?
				if( [cset characterIsMember: [[s string] characterAtIndex: (vStartOffs -1)]] )  // If charset is NIL, this evaluates to NO.
					continue;
			}
			
			if( (vStartOffs +[ident length] +1) < [s length] )
			{
				// Alphanum character following our identifier?
				if( [cset characterIsMember: [[s string] characterAtIndex: (vStartOffs +[ident length])]] )  // If charset is NIL, this evaluates to NO.
					continue;
			}
			
			// Now mess with the string's styles:
			[s setAttributes: vStyles range: NSMakeRange( vStartOffs, [ident length] )];
				
			[progress animate:nil];
		}
		
	NS_HANDLER
		// Just ignore it, syntax coloring isn't that important.
	NS_ENDHANDLER
}


/* -----------------------------------------------------------------------------
	colorTagFrom:
		Colorize HTML tags or similar constructs in the text view.
	
	REVISIONS:
		2004-05-18  witness Documented.
   -------------------------------------------------------------------------- */

-(void)	colorTagFrom: (NSString*) startCh to: (NSString*)endCh inString: (NSMutableAttributedString*) s
				withColor: (NSColor*) col andMode:(NSString*)attr exceptIfMode: (NSString*)ignoreAttr
{
	NS_DURING
		NSScanner*					vScanner = [NSScanner scannerWithString: [s string]];
		NSDictionary*				vStyles = [NSDictionary dictionaryWithObjectsAndKeys:
													col, NSForegroundColorAttributeName,
													attr, TD_SYNTAX_COLORING_MODE_ATTR,
													nil];
		
		while( ![vScanner isAtEnd] )
		{
			int		vStartOffs,
					vEndOffs;
			
			// Look for start of one-line comment:
			[vScanner scanUpToString: startCh intoString: nil];
			vStartOffs = [vScanner scanLocation];
			if( vStartOffs >= [s length] )
				NS_VOIDRETURN;
			NSString*   scMode = [[s attributesAtIndex:vStartOffs effectiveRange: nil] objectForKey: TD_SYNTAX_COLORING_MODE_ATTR];
			if( ![vScanner scanString:startCh intoString:nil] )
				NS_VOIDRETURN;
			
			// If start lies in range of ignored style, don't colorize it:
			if( ignoreAttr != nil && [scMode isEqualToString: ignoreAttr] )
				continue;

			// Look for matching end marker:
			while( ![vScanner isAtEnd] )
			{
				// Scan up to the next occurence of the terminating sequence:
				(BOOL) [vScanner scanUpToString: endCh intoString:nil];
				
				// Now, if the mode of the end marker is not the mode we were told to ignore,
				//  we're finished now and we can exit the inner loop:
				vEndOffs = [vScanner scanLocation];
				if( vEndOffs < [s length] )
				{
					scMode = [[s attributesAtIndex:vEndOffs effectiveRange: nil] objectForKey: TD_SYNTAX_COLORING_MODE_ATTR];
					[vScanner scanString: endCh intoString: nil];   // Also skip the terminating sequence.
					if( ignoreAttr == nil || ![scMode isEqualToString: ignoreAttr] )
						break;
				}
				
				// Otherwise we keep going, look for the next occurence of endCh and hope it isn't in that style.
			}
			
			vEndOffs = [vScanner scanLocation];
			
			// Now mess with the string's styles:
			[s setAttributes: vStyles range: NSMakeRange( vStartOffs, vEndOffs -vStartOffs )];
				
			[progress animate:nil];
		}
	NS_HANDLER
		// Just ignore it, syntax coloring isn't that important.
	NS_ENDHANDLER
}


/* -----------------------------------------------------------------------------
	defaultTextAttributes:
		Return the text attributes to use for the text in our text view.
	
	REVISIONS:
		2004-05-18  witness Documented.
   -------------------------------------------------------------------------- */

-(NSDictionary*)	defaultTextAttributes
{
	return [NSDictionary dictionaryWithObject: [NSFont userFixedPitchFontOfSize:10.0] forKey: NSFontAttributeName];
}




@end
