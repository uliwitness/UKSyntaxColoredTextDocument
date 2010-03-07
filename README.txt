UKSYNTAXCOLOREDTEXTDOCUMENT 0.4

This is a document class that implements a text editor that performs "live"
syntax coloring on its documents, and generally tries to be helpful to editing
structured text documents for programming.


FEATURES?

-> Live syntax coloring as you type, fast through localized updates
-> Most information about the things to colorize is kept in a
   SyntaxDefinitions.plist file that can easily be adapted to other programming
   languages than the included Objective C and HTML.
-> All colors used have aesthetically pleasing defaults and are read from the
   user defaults database. That means no more pink, turquoise and brown unless
   you want these colors. And the defaults are initially fetched from the syntax
   definitions, which you can adjust for your apps.
-> Built-in support for "Go To Line" and "Go To Character" to select parts of
   the text, also useful for highlighting lines when reporting coding errors.
-> Controller classes for editing preferences included.
-> Maintains indentation (if desired).


ADAPTING TO OTHER PROGRAMMING LANGUAGES

To adapt the syntax coloring to another language, change the
SyntaxDefinition.plist file using Apple's Property List Editor. A syntax
definition file is an NSDictionary saved as a property list (and can thus be
edited using Apple's Property List Editor). It currently contains two required
entries.

The first has the key "Components", which is an array of dictionaries each
describing one "thing" that can be colorized. Here's what the various keys mean:

Name		-   The name of this component that can be colorized. Used
				internally to mark some text styles, and also used to refer to
				this component from other components. (NSString)
Color		-   The default color to use for coloring this component. This will
				only be used when the user didn't specify a different color in
				the NSUserDefaults. Colors in the user defaults should have the
				key "SyntaxColoring:Color:COMPNAME" where COMPNAME is the name
				you specified as "Name" for this component.
				(NSArray, Red, Green, Blue, Alpha)
Type		-   The type of this component. This can be any one of "String",
				"BlockComment", "Tag", "OneLineComment" or "Keywords" and
				decides what other keys you should put into this component.
				(NSString)
				
Start		-   The character or character sequence that indicates the beginning
				of a range of text belonging to this component. (Not needed for
				"Keywords"). (NSString)
End			-   The character or character sequence that indicates the end of a
				range of text belonging to this component. (Not needed for
				"Keywords" or "OneLineComment"). (NSString)
EscapeChar  -   The character to use for indicating an "Escape sequence" in a
				"String". This character will cause the next character to be
				ignored in determining if this is an end of a "String".
				(NSString)
IgnoredComponent -
				The "Name" of another component in which this "Tag" range may
				not start or end. This can be used, when parsing HTML tags, to
				ignore '>' characters when they are specified inside a quoted
				character, so they're not accidentally considered as being the
				end of the tag. (NSString)
Keywords	-   An array of keyword strings to be colorized (Only used for
				"Keywords"-type components). If this isn't specified for a
				"Keywords" component, this will look in NSUserDefaults for an
				array under the key "SyntaxColoring:Keywords:COMPNAME", where
				COMPNAME is the "Name" you specified for this component. You can
				use this to colorize keywords or to colorize user-defined keywords.
				(NSArray of NSStrings)
Charset		-   All characters that are valid in a keyword for this "Keywords"
				style. Specify both upper- and lowercase characters separately.
				If this is specified, only keywords that are preceded and
				followed by characters not listed here will be colored, thus
				enforcing complete matches. Otherwise, parts of keywords will
				be colored as well, if they match an item in the "Keywords"
				list. (NSString)

Colorizing is done in the order the components are listed in the array. So, if
you colorize strings first and comments afterward, any strings occurring inside
a comment will get the comment color, because that color was applied last.

The second entry is "FileNameSuffixes", which is an array of strings, each
designating one file name extension which UKMultiSyntaxColoredTextDocument will
use to determine the syntax coloring file to use for an opened file.

Currently, you can also put the following optional keys in the dictionary:

OneLineCommentPrefix	-	A string that will be used by the action method
							-toggleCommentForSelection: to determine what
							comment character sequence to look for/to add.
							Note that if this entry has leading or trailing
							whitespace, that whitespace will be added when
							inserting a new comment, but when trying to determine
							whether a line has a comment that should be removed,
							it will also match the string without the whitespace.
							This could cause problems in languages where
							whitespace is syntactically relevant.


WHAT LICENSE IS THIS UNDER?

Copyright (c) 2003-2010 Uli Kusterer.

This software is provided 'as-is', without any express or implied
warranty. In no event will the authors be held liable for any damages
arising from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it
freely, subject to the following restrictions:

   1. The origin of this software must not be misrepresented; you must not
   claim that you wrote the original software. If you use this software
   in a product, an acknowledgment in the product documentation would be
   appreciated but is not required.

   2. Altered source versions must be plainly marked as such, and must not be
   misrepresented as being the original software.

   3. This notice may not be removed or altered from any source
   distribution.


REVISIONS:
	0.1	-	First public release.
	0.1.1 - Fixed a tiny bug that could cause a crash when the last character in
			the document was deleted. Removed a couple of outdated files and
			added some missing identifiers to the example SyntaxDefinition.plist.
	0.1.5 - Added option to maintain indentation of previous line for new lines
			when a return key is typed, added accessors for auto syntax coloring
			and maintain indentation flags.
	0.2.0 - Added "Identifiers2" list, "comments2", coloring of "tags",
			-syntaxDictionary method, support for specifying the escape
			character for coloring strings, HTML sample syntax definition,
			leaving out the charset for identifiers, icons indicating selection
			type, UKSCTDColorWellPrefsController, new-style syntax definitions
			and UKSCTDUserIdentifiersPrefsController, and UKMultiSyntaxColoredTextDocument.
	0.3.0 - Fixed exceptions when undoing, hopefully finally fixed the bug where
			editing an empty document would occasionally crash.
	0.4.0 - Fixed indent/unindent to not indent the next line after a full-line
			(triple click) selection and made it support undo. Made "new" ObjC
			coloring scheme support user identifiers, added more identifiers.
			Multi syntax colored document now tries to pick the right syntax
			coloring definition file based on extension. Misc. stability fixes.


CONTACT INFORMATION

You can find the newest version of UKSyntaxColoredTextDocument at
	http://github.com/uliwitness/UKSyntaxColoredTextDocument

E-Mail: witness_dot_of_dot_teachtext_at_gmx_dot_net

