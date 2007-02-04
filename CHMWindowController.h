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
// $Revision: 1.5 $
//

#import <Cocoa/Cocoa.h>

@class WebView;

@interface CHMWindowController : NSWindowController
{
    IBOutlet WebView *_contentsView;
    IBOutlet NSDrawer *_drawer;
    IBOutlet NSOutlineView *_tocView;
    IBOutlet NSTableView *_favoritesView;
    IBOutlet NSTabView *_drawerView;
    IBOutlet id _historyToolbarItemView;
}

- (void)setupToolbar;
- (void)updateToolTipRects;

- (IBAction)toggleDrawer:(id)sender;
- (IBAction)changeTopicWithSelectedRow:(id)sender;
- (IBAction)changeTopicToPreviousInHistory:(id)sender;
- (IBAction)changeTopicToNextInHistory:(id)sender;
- (IBAction)makeTextSmaller:(id)sender;
- (IBAction)makeTextBigger:(id)sender;

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar;
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar;
- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag;

- (BOOL)validateMenuItem:(NSMenuItem*)anItem;


@end
