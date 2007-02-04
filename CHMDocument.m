//
// Chmox a CHM file viewer for Mac OS X
// Copyright (c) 2004 Stphane Boisson.
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
// $Revision: 1.6 $
//

#import "CHMDocument.h"
#import "CHMTopic.h"
#import "CHMWindowController.h"
#import "CHMContainer.h"
#import "CHMTableOfContents.h"
#import "CHMURLProtocol.h"

@class NSFileManager;

@implementation CHMDocument

#pragma mark NSObject
- (id) init
{
    if( self = [super init] ) {
        _container = nil;
    }
	KEY_savedBookmarks = @"Chmox:savedBookmarks";
    return self;
}


- (void) dealloc
{
    if( _container ) {
		[CHMURLProtocol unregisterContainer:_container];
		[_tableOfContents release];
		[_container release];
    }
	[self setLastLoadedPage:nil];
    [self setLastLoadedPageName:nil];
    [super dealloc];
}

#pragma mark Preferences
- (void) readPreferences
{
	KEY_savedBookmarks = [KEY_savedBookmarks stringByAppendingString:[_container uniqueId]];
	NSDictionary *savedBookmarks = [[NSUserDefaults standardUserDefaults] dictionaryForKey: KEY_savedBookmarks];
	if (savedBookmarks == nil){
		bookmarks = [[NSMutableDictionary alloc] init];
	} else{
		bookmarks = [[NSMutableDictionary alloc] initWithDictionary:savedBookmarks];
	}
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *appDefaults = [NSDictionary dictionaryWithObject:bookmarks forKey:KEY_savedBookmarks];
	[defaults registerDefaults:appDefaults];
	
}

#pragma mark NSDocument

- (void)makeWindowControllers
{
    _windowController = [[CHMWindowController alloc] initWithWindowNibName:@"CHMDocument"];
    [self addWindowController:_windowController];
	[_windowController setDocument: self];
    [_windowController release];
}


- (BOOL)readFromFile:(NSString *)fileName ofType:(NSString *)docType {
    //NSLog( @"CHMDocument:readFromFile:%@", fileName );
    
    _container = [CHMContainer containerWithContentsOfFile:fileName];
    if( !_container ) return NO;
	
    [CHMURLProtocol registerContainer:_container];
    _tableOfContents = [[CHMTableOfContents alloc] initWithContainer:_container];

	[self readPreferences];
	[self openIndex];
    return YES;
}

- (NSData *)dataRepresentationOfType:(NSString *)type {
    // Viewer only
    return nil;
}


#pragma mark CHM operations
- (NSURL *)urlForSelectedSearchResult: (int)selectedIndex
{
	id target = [searchResults objectForKey:[[searchResults allKeys] objectAtIndex:selectedIndex]];
	return [NSURL URLWithString:target];
}

- (int) searchResultsCount
{
	return [searchResults count];
}

- (id) searchResultAtIndex: (int) requestedIndex
{
	return [[searchResults allKeys] objectAtIndex:requestedIndex];
}


#pragma mark Bookmark operations
- (void)addBookmark
{
	if(lastLoadedPage != nil){	
		[bookmarks setObject:lastLoadedPage forKey:lastLoadedPageName];
		[[NSUserDefaults standardUserDefaults] setObject:bookmarks forKey:KEY_savedBookmarks];
	}
}

- (void)removeBookmark: (int)bookmarkIndex
{
	[bookmarks removeObjectForKey:[[bookmarks allKeys] objectAtIndex:bookmarkIndex]];
	[[NSUserDefaults standardUserDefaults] setObject:bookmarks forKey:KEY_savedBookmarks];
}

- (int) bookmarkCount
{
	return [bookmarks count];
}

- (NSString *) bookmarkURLAtIndex: (int) selectedIndex;
{
	return [bookmarks objectForKey: [[bookmarks allKeys] objectAtIndex:selectedIndex]];
}

- (NSString *) bookmarkTitleAtIndex: (int) selectedIndex;
{
	return [[bookmarks allKeys] objectAtIndex:selectedIndex];
}


#pragma mark Search operations
//..........................................................................

// specify the maximum number of hits
#define kSearchMax 1000

/**
 * The main search method.
 * This method is responsible for searching ...
 * TODO: finish
 */
- (void) search:(NSString *)query
{
	[searchResults release];
	searchResults = [[NSMutableDictionary alloc] init];
	//..........................................................................
	// set up search options
    SKSearchOptions options = kSKSearchOptionDefault;
    //if ([searchOptionNoRelevance intValue]) options |= kSKSearchOptionNoRelevanceScores;
    //if ([searchOptionSpaceIsOR intValue]) options |= kSKSearchOptionSpaceMeansOR;
    //if ([searchOptionSpaceFindSimilar intValue]) options |= kSKSearchOptionFindSimilar;
	
	//..........................................................................
	// create an asynchronous search object 
    SKSearchRef search = SKSearchCreate (skIndex, (CFStringRef) query, options);
    [(id) search autorelease];
	
	//..........................................................................
	// get matches from a search object
    Boolean more = true;
    UInt32 totalCount = 0;
	
    while (more) {
        SKDocumentID    foundDocIDs [kSearchMax];
        float            foundScores [kSearchMax];
        SKDocumentRef    foundDocRefs [kSearchMax];
        float * scores;
        Boolean unranked = options & kSKSearchOptionNoRelevanceScores;
		
        if (unranked) {
            scores = NULL;
        } else {
            scores = foundScores;
        }
		
        CFIndex foundCount = 0;
        CFIndex pos;
		int timeOutInSeconds = 1;
        more =    SKSearchFindMatches (search, kSearchMax, foundDocIDs, scores, timeOutInSeconds, &foundCount);
        totalCount += foundCount;
		
		//..........................................................................
		// get document locations for matches and display results.
		//     alternatively, you can collect results over iterations of this loop
		//     for display later.
        SKIndexCopyDocumentRefsForDocumentIDs ( (SKIndexRef) skIndex, (CFIndex) foundCount, (SKDocumentID *) foundDocIDs,
											   (SKDocumentRef *) foundDocRefs);
		
        for (pos = 0; pos < foundCount; pos++) {
            SKDocumentRef doc = (SKDocumentRef) [(id) foundDocRefs [pos] autorelease];
            NSURL* url = [(id) SKDocumentCopyURL (doc) autorelease];
            NSString* urlStr = [url absoluteString];
            NSString* desc;
			
            if (unranked) {
                desc = [NSString stringWithFormat: @"---\nDocID: %d, URL: %@", (int) foundDocIDs [pos], urlStr];
            } else {
                desc = [NSString stringWithFormat: @"---\nDocID: %d, Score: %f, URL: %@", (int) foundDocIDs[ pos], foundScores [pos], urlStr];
            }
            NSLog(@"%@", desc);
			NSString* entries = [docTitles objectForKey:urlStr ];
			[searchResults setValue:urlStr forKey:[docTitles objectForKey:urlStr ] ];
        }
    }
	
    NSString * desc = [NSString stringWithFormat: @"\"%@\" - %d matches", query, (int) totalCount];
	NSLog(@"%@", desc);
}

- (void) addDocWithTextForURL: (NSURL *) aURL
{
    SKDocumentRef doc = SKDocumentCreateWithURL ( (CFURLRef) aURL );
    [(id) doc autorelease];
	
	NSString* path = [aURL relativePath];
    NSString * contents = [_container stringWithContentsOfObject: path ];
    SKIndexAddDocumentWithText (skIndex, doc, (CFStringRef) contents, (Boolean) true );
}

- (void) populateIndexWithSubTopic: (CHMTopic *)aTopic
{
	[self addDocWithTextForURL: [aTopic location]];
	[docTitles setValue:[aTopic name] forKey:[[aTopic location] absoluteString] ];
	for(int topicIndex = 0; topicIndex < [aTopic countOfSubTopics]; topicIndex++){
		[self populateIndexWithSubTopic: [aTopic objectInSubTopicsAtIndex: topicIndex]];
	}
}

- (void) populateIndex
{
	NSArray* topics = [_tableOfContents rootTopics];
	NSEnumerator* enumerator = [topics objectEnumerator];
	
	CHMTopic* aTopic;
	while (aTopic = [enumerator nextObject]) {
		[self populateIndexWithSubTopic: aTopic];
	}
	SKIndexFlush(skIndex);
}

- (void) createNewIndexAtPath:(NSString *)path
{
	NSString* parentDirectory = [path stringByDeletingLastPathComponent];
	if(! [[NSFileManager defaultManager] fileExistsAtPath:parentDirectory]){
		[[NSFileManager defaultManager] createDirectoryAtPath:parentDirectory attributes:nil];
	}
	[[NSFileManager defaultManager] createFileAtPath:path contents:nil attributes:nil];
    NSURL* url = [NSURL fileURLWithPath: path];
    SKIndexType type = kSKIndexInverted;
    skIndex = SKIndexCreateWithURL( (CFURLRef) url, (CFStringRef) @"PrimaryIndex", (SKIndexType) type, (CFDictionaryRef) NULL );
	NSLog(@"New index: %@", skIndex);
	[self populateIndex];
}

- (void) openIndex
{
	NSString* basePath = [@"~/Library/Application Support/Chmox/" stringByExpandingTildeInPath];
	NSString* documentName = [[[_container path] stringByDeletingPathExtension] lastPathComponent];
	NSString* path = [[basePath stringByAppendingString:@"/"] stringByAppendingString: documentName ];
	path = [path stringByAppendingString:@".idx"];
	NSString* tocPath = [[path stringByDeletingPathExtension] stringByAppendingString: @".tt"];
	if([[NSFileManager defaultManager] fileExistsAtPath: path]){
		NSURL* url = [NSURL fileURLWithPath:path];
		// open the specified index
		skIndex = SKIndexOpenWithURL( (CFURLRef) url, (CFStringRef) @"PrimaryIndex", true );
		docTitles = [[NSMutableDictionary dictionaryWithContentsOfFile: tocPath] retain];
	} else {
		docTitles = [[NSMutableDictionary alloc] init];
		[self createNewIndexAtPath: path];
		[docTitles writeToFile:tocPath atomically:TRUE];
	}
	
//	[basePath autorelease];
//	[documentName autorelease];
//	[path autorelease];
}

-(void) closeIndex
{
    if (skIndex) {
        SKIndexClose (skIndex);
        skIndex = nil;
    }
}


#pragma mark Accessors

- (NSString *)title
{
    return [_container title];
}

- (NSURL *)currentLocation
{
    return [CHMURLProtocol URLWithPath:[_container homePath] inContainer:_container];
}

- (CHMTableOfContents *)tableOfContents
{
    return _tableOfContents;
}

- (NSString *)uniqueId
{
    return [_container uniqueId];
}
- (CHMContainer *)container
{
    return [[_container retain] autorelease];
}

//=========================================================== 
//  lastLoadedPage 
//=========================================================== 
- (NSString *)lastLoadedPage
{
    return [[lastLoadedPage retain] autorelease]; 
}
- (void)setLastLoadedPage:(NSString *)aLastLoadedPage
{
    if (lastLoadedPage != aLastLoadedPage) {
        [lastLoadedPage release];
        lastLoadedPage = [aLastLoadedPage copy];
    }
}

//=========================================================== 
//  lastLoadedPageName 
//=========================================================== 
- (NSString *)lastLoadedPageName
{
    return [[lastLoadedPageName retain] autorelease]; 
}
- (void)setLastLoadedPageName:(NSString *)aLastLoadedPageName
{
    if (lastLoadedPageName != aLastLoadedPageName) {
        [lastLoadedPageName release];
        lastLoadedPageName = [aLastLoadedPageName copy];
    }
}




@end
