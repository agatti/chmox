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
// $Revision: 1.5 $
//

#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>

@class CHMWindowController;
@class CHMContainer;
@class CHMTableOfContents;
@class CHMTopic;
@class NSURL;

@interface CHMDocument : NSDocument {
    @private
    CHMWindowController*	_windowController;

    CHMContainer*			_container;
    CHMTableOfContents*		_tableOfContents;

    NSDictionary*			searchResults;
	NSString*				KEY_savedBookmarks;
	NSMutableDictionary*	bookmarks;
	NSString*				lastLoadedPage;
	NSString*				lastLoadedPageName;
	
	SKIndexRef				skIndex;
	NSMutableDictionary*	docTitles;
}

- (NSString *)title;
- (NSURL *)currentLocation;
- (CHMTableOfContents *)tableOfContents;
- (NSString *)uniqueId;

- (CHMContainer *)container;
- (void)search:(NSString *)searchString;

- (int) searchResultsCount;
- (id) searchResultAtIndex: (int) index;
- (NSURL *)urlForSelectedSearchResult: (int)selectedIndex;

- (void)addBookmark;
- (void)removeBookmark: (int)bookmarkIndex;
- (int) bookmarkCount;
- (NSString *) bookmarkURLAtIndex: (int) index;
- (NSString *) bookmarkTitleAtIndex: (int) index;

- (NSString *)lastLoadedPage;
- (void)setLastLoadedPage:(NSString *)aLastLoadedPage;

- (NSString *)lastLoadedPageName;
- (void)setLastLoadedPageName:(NSString *)aLastLoadedPageName;

- (void) addDocWithTextForURL: (NSURL *) aURL;
- (void) populateIndexWithSubTopic: (CHMTopic *)aTopic;
- (void) populateIndex;
- (void) createNewIndexAtPath:(NSString *)path;
- (void) openIndex;
- (void) closeIndex;


@end
