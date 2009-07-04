//
//  NSScanner+SkipUpToCharset.h
//  UKSyntaxColoredDocument
//
//  Created by Uli Kusterer on Sat Dec 13 2003.
//  Copyright (c) 2003 M. Uli Kusterer. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSScanner (SkipUpToCharset)

-(BOOL) skipUpToCharactersFromSet:(NSCharacterSet*)set;

@end
