//
// Chmox a CHM file viewer for Mac OS X
// Copyright (c) 2004 Stéphane Boisson.
//
// Chmox is free software; you can redistribute it and/or modify it
// under the terms of the GNU Lesser General Public License as published
// by the Free Software Foundation; either version 2.1 of the License, or
// (at your option) any later version.
//
// Chmox is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
// 
// You should have received a copy of the GNU Lesser General Public License
// along with Foobar; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
//
// $Revision: 1.8 $
//

#include <openssl/sha.h>
#import "CHMContainer.h"
#import "chm_lib.h"

@implementation CHMContainer

#pragma mark Factory

+ (id)containerWithContentsOfFile:(NSString *)chmFilePath
{
    return [[CHMContainer alloc] initWithContentsOfFile:chmFilePath];
}


#pragma mark Lifecycle

- (id)initWithContentsOfFile:(NSString *)chmFilePath
{
    if( self = [super init] ) {
	_handle = chm_open( [chmFilePath fileSystemRepresentation] );
	if( !_handle ) return nil;
	
	_path = [chmFilePath retain];
	
	_uniqueId = nil;
	_title = nil;
	_homePath = nil;
	_tocPath = nil;
	_indexPath = nil;

	[self loadMetadata];
    }
    
    return self;
}


- (void) dealloc
{
    NSLog(@"deallocating %@",self);
    [_path release];

    if( _handle ) {
        chm_close( _handle );
    }

    [_uniqueId release];
    [_title release];
    [_homePath release];
    [_tocPath release];
    [_indexPath release];
}


#pragma mark Accessors

- (NSString *)homePath
{
    return _homePath;
}

- (NSString *)title
{
    return _title;
}

- (NSString *)uniqueId 
{
    return _uniqueId;
}

- (NSString *)tocPath
{
    return _tocPath;
}

#pragma mark Basic CHM reading operations

static inline unsigned short readShort( NSData *data, unsigned int offset ) {
    NSRange valueRange = { offset, 2 };
    unsigned short value;
    
    [data getBytes:(void *)&value range:valueRange];
    return NSSwapLittleShortToHost( value );
}

static inline unsigned long readLong( NSData *data, unsigned int offset ) {
    NSRange valueRange = { offset, 4 };
    unsigned long value;
    
    [data getBytes:(void *)&value range:valueRange];
    return NSSwapLittleLongToHost( value );
}

static inline NSString * readString( NSData *data, unsigned long offset ) {
    const char *stringData = (char *)[data bytes] + offset;
    return [NSString stringWithUTF8String:stringData];
}

static inline NSString * readTrimmedString( NSData *data, unsigned long offset ) {
    const char *stringData = (char *)[data bytes] + offset;
    return [[NSMutableString stringWithUTF8String:stringData] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

#pragma mark CHM Object loading

- (BOOL)hasObjectWithPath: (NSString *)path
{
    struct chmUnitInfo info;
    if( chm_resolve_object( _handle, [path UTF8String], &info ) != CHM_RESOLVE_SUCCESS ) {
        return NO;
    }

    return YES;
}

- (NSData *)dataWithContentsOfObject: (NSString *)path
{
    //NSLog( @"dataWithContentsOfObject: %@", path );
    if( !path ) {
	return nil;
    }
    
    if( [path hasPrefix:@"/"] ) {
	// Quick fix
	if( [path hasPrefix:@"///"] ) {
	    path = [path substringFromIndex:2];
	}
    }
    else {
	path = [NSString stringWithFormat:@"/%@", path];
    }
    
    struct chmUnitInfo info;
    if( chm_resolve_object( _handle, [path UTF8String], &info ) != CHM_RESOLVE_SUCCESS ) {
        NSLog( @"Unable to find %@", path );
        return nil;
    }
    
    DEBUG_OUTPUT( @"Found object %@ (%qu bytes)", path, (long long)info.length );
    
    void *buffer = malloc( info.length );
    
    if( !buffer ) {
	// Allocation failed
	NSLog( @"Failed to allocate %qu bytes for %@", (long long)info.length, path );
	return nil;
    }
    
    if( !chm_retrieve_object( _handle, &info, buffer, 0, info.length ) ) {
	NSLog( @"Failed to load %qu bytes for %@", (long long)info.length, path );
	free( buffer );
	return nil;
    }
    
    return [NSData dataWithBytesNoCopy:buffer length:info.length];
}

- (NSString *)stringWithContentsOfObject: (NSString *)objectPath
{
    NSData *data = [self dataWithContentsOfObject:objectPath];
    if( data ) {
	// NSUTF8StringEncoding / NSISOLatin1StringEncoding / NSUnicodeStringEncoding
	return [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    }
    
    return nil;
}

- (NSData *)dataWithTableOfContents
{
    return [self dataWithContentsOfObject:_tocPath];
}


#pragma mark CHM setup

- (BOOL)loadMetadata {
    //--- Start with WINDOWS object ---
    NSData *windowsData = [self dataWithContentsOfObject:@"/#WINDOWS"];
    NSData *stringsData = [self dataWithContentsOfObject:@"/#STRINGS"];

    if( windowsData && stringsData ) {
	const unsigned long entryCount = readLong( windowsData, 0 );
	const unsigned long entrySize = readLong( windowsData, 4 );
	NSLog( @"Entries: %u x %u bytes", entryCount, entrySize );
	
	for( int entryIndex = 0; entryIndex < entryCount; ++entryIndex ) {
	    unsigned long entryOffset = 8 + ( entryIndex * entrySize );
	    
	    if( !_title || ( [_title length] == 0 ) ) { 
		_title = readTrimmedString( stringsData, readLong( windowsData, entryOffset + 0x14 ) );
		NSLog( @"Title: %@", _title );
	    }
	    
	    if( !_tocPath || ( [_tocPath length] == 0 ) ) { 
		_tocPath = readString( stringsData, readLong( windowsData, entryOffset + 0x60 ) );
		NSLog( @"Table of contents: %@", _tocPath );
	    }
	    
	    if( !_indexPath || ( [_indexPath length] == 0 ) ) { 
		_indexPath = readString( stringsData, readLong( windowsData, entryOffset + 0x64 ) );
		NSLog( @"Index: %@", _indexPath );
	    }
	    
	    if( !_homePath || ( [_homePath length] == 0 ) ) { 
		_homePath = readString( stringsData, readLong( windowsData, entryOffset + 0x68 ) );
		NSLog( @"Home: %@", _homePath );
	    }
	}
    }
    
    //--- Use SYSTEM object ---
    NSData *systemData = [self dataWithContentsOfObject:@"/#SYSTEM"];
    if( systemData == nil ) {
	return NO;
    }
        
    unsigned int maxOffset = [systemData length];
    for( unsigned int offset = 0; offset < maxOffset; offset += readShort( systemData, offset + 2 ) + 4 ) {
	switch( readShort( systemData, offset ) ) {
	    // Table of contents file
	    case 0:
		if( !_tocPath || ( [_tocPath length] == 0 ) ) {
		    _tocPath = readString( systemData, offset + 4 );
                    NSLog( @"SYSTEM Table of contents: %@", _tocPath );
		}
		break;
		
		// Index file
	    case 1:
		if( !_indexPath || ( [_indexPath length] == 0 ) ) {
		    _indexPath = readString( systemData, offset + 4 );
                    NSLog( @"SYSTEM Index: %@", _indexPath );
		}
		break;
		
		// Home page
	    case 2:
		if( !_homePath || ( [_homePath length] == 0 ) ) {
		    _homePath = readString( systemData, offset + 4 );
                    NSLog( @"SYSTEM Home: %@", _homePath );
		}
		break;
		
		// Title
	    case 3:
		if( !_title || ( [_title length] == 0 ) ) {
		    _title = readTrimmedString( systemData, offset + 4 );
		    NSLog( @"SYSTEM Title: %@", _title );
		}
		break;
		
		// Compiled file
	    case 6:
		NSLog( @"SYSTEM compiled file: %@", readString( systemData, offset + 4 ) );
		break;
		
		// Compiler
	    case 9:
		NSLog( @"SYSTEM Compiler: %@", readString( systemData, offset + 4 ) );
		break;
		
		// Default font
	    case 16:
		NSLog( @"SYSTEM Default font: %@", readString( systemData, offset + 4 ) );
		break;
		
		// Other data not handled
	    default:
		break;
	}
    }

    //--- Compute unique id ---
    unsigned char digest[ SHA_DIGEST_LENGTH ];
    SHA1( [systemData bytes], [systemData length], digest );
    unsigned int *ptr = (unsigned int *) digest;
    _uniqueId = [[NSString alloc] initWithFormat:@"%x%x%x%x%x", ptr[0], ptr[1], ptr[2], ptr[3], ptr[4]];
    NSLog( @"UniqueId=%@", _uniqueId );

    // Check for empty string titles
    if( [_title length] == 0 )  {
        _title = nil;
    }
    else {
        [_title retain];
    }

    // Check for lack of index page
    if( !_homePath ) {
        _homePath = [self findHomeForPath:@"/"];
        NSLog( @"Implicit home: %@", _homePath );
    }
    
    [_homePath retain];
    [_tocPath retain];
    [_indexPath retain];
    
    return YES;
}


- (NSString *)findHomeForPath: (NSString *)basePath
{
    NSString *testPath;
    
    NSString *separator = [basePath hasSuffix:@"/"]? @"" : @"/";
    testPath = [NSString stringWithFormat:@"%@%@index.htm", basePath, separator];
    if( [self hasObjectWithPath:testPath] ) {
        return testPath;
    }

    testPath = [NSString stringWithFormat:@"%@%@default.html", basePath, separator];
    if( [self hasObjectWithPath:testPath] ) {
        return testPath;
    }

    testPath = [NSString stringWithFormat:@"%@%@default.htm", basePath, separator];
    if( [self hasObjectWithPath:testPath] ) {
        return testPath;
    }

    return [NSString stringWithFormat:@"%@%@index.html", basePath, separator];
}


- (BOOL)setupFromSystemObject {
    
    return YES;
}

@end
