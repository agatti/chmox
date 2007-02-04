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
// $Revision: 1.10 $
//

#import "WebKit/WebKit.h"
#import "CHMWindowController.h"
#import "CHMDocument.h"
#import "CHMTopic.h"
#import "CHMURLProtocol.h"


@implementation CHMWindowController

// Tab items
static NSString *TOC_TAB_ID = @"tocTab";
static NSString *SEARCH_TAB_ID = @"searchTab";
static NSString *FAVORITES_TAB_ID = @"favoritesTab";

// Toolbar items
static NSString *DRAWER_TOGGLE_TOOL_ID = @"chmox.drawerToggle";
static NSString *SMALLER_TEXT_TOOL_ID = @"chmox.smallerText";
static NSString *BIGGER_TEXT_TOOL_ID = @"chmox.biggerText";
static NSString *HISTORY_TOOL_ID = @"chmox.history";


#pragma mark NSWindowController overridden method

- (void)windowDidLoad
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[[self document] currentLocation]];
    [[_contentsView mainFrame] loadRequest:request];

    [self setWindowFrameAutosaveName:[[self document] uniqueId]];
    [self setShouldCloseDocument:YES];
       
    [_tocView setDataSource:[[self document] tableOfContents]];
    [_tocView setAutoresizesOutlineColumn:NO];
    
    [self updateToolTipRects];
    [self setupToolbar];
    
    int tabIndex;
    
    // Remove Search tab
    tabIndex = [_drawerView indexOfTabViewItemWithIdentifier:SEARCH_TAB_ID];
    if( tabIndex != NSNotFound ) {
	[_drawerView removeTabViewItem:[_drawerView tabViewItemAtIndex:tabIndex]];
    }

    // Remove Favorites tab
    tabIndex = [_drawerView indexOfTabViewItemWithIdentifier:FAVORITES_TAB_ID];
    if( tabIndex != NSNotFound ) {
	[_drawerView removeTabViewItem:[_drawerView tabViewItemAtIndex:tabIndex]];
    }
    
    [_drawer open];
}

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName
{
    // TODO: user preferences to display filename or doc title
    NSString *windowTitle = [[self document] title];
    return windowTitle? windowTitle : displayName;
}


#pragma mark WebPolicyDelegate

// Open external URLs in external viewer
- (void)webView:(WebView *)sender decidePolicyForNavigationAction:(NSDictionary *)actionInformation
	request:(NSURLRequest *)request
	  frame:(WebFrame *)frame decisionListener:(id<WebPolicyDecisionListener>)listener
{
    if( [CHMURLProtocol canHandleURL:[request URL]] ) {
	[listener use];
    } else {
	NSLog( @"Opening external URL %@", [request URL]);
	[[NSWorkspace sharedWorkspace] openURL:[request URL]];
	[listener ignore];
    }
}

// Open external URLs in new window in external viewer
- (void)webView:(WebView *)sender 
	decidePolicyForNewWindowAction:(NSDictionary *)actionInformation 
	request:(NSURLRequest *)request 
	newFrameName:(NSString *)frameName 
	decisionListener:(id<WebPolicyDecisionListener>)listener
{
    NSLog( @"WebPolicyDelegate: decidePolicyForNewWindowAction called %@", [request URL]);

    if( [CHMURLProtocol canHandleURL:[request URL]] ) {
	// Need testing
	[listener use];
    } else {
	NSLog( @"Opening external URL %@", [request URL]);
	[[NSWorkspace sharedWorkspace] openURL:[request URL]];
	[listener ignore];
    }
}
	
	
#pragma mark WebUIDelegate 

- (NSArray *)webView:(WebView *)sender 
    contextMenuItemsForElement:(NSDictionary *)element
    defaultMenuItems:(NSArray *)defaultMenuItems
{
    NSLog( @"contextMenuItemsForElement: %@", element );

    NSURL *link = [element objectForKey:WebElementLinkURLKey];
    
    if( link && [CHMURLProtocol canHandleURL:link] ) {
	// No context menu for internal links
	return nil;
    }
    
    return defaultMenuItems;
}

- (void)webView:(WebView *)sender mouseDidMoveOverElement:(NSDictionary *)elementInformation
  modifierFlags:(unsigned int)modifierFlags
{
    //NSLog( @"mouseDidMoveOverElement: %@", elementInformation );
}

#pragma mark NSToolTipOwner

- (NSString *)view:(NSView *)view
  stringForToolTip:(NSToolTipTag)tag
	     point:(NSPoint)point
	  userData:(void *)userData
{
    if( view == _tocView ) {
	int row = [_tocView rowAtPoint:point];
	
	if( row >= 0 ) {
	    return [[_tocView itemAtRow:row] name];
	}
    }
    
    return nil;
}

- (void)updateToolTipRects
{
    [_tocView removeAllToolTips];
    NSRange range = [_tocView rowsInRect:[_tocView visibleRect]];
    
    for( int i = range.location; i < NSMaxRange( range ); ++i ) {
	[_tocView addToolTipRect:[_tocView rectOfRow:i] owner:self userData:NULL];
    }
}

#pragma mark NSOutlineView delegate

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    // TODO: Change icon
}

#pragma mark Menu Validation

- (BOOL)validateMenuItem:(NSMenuItem*)anItem {
    if( [anItem action] == @selector( changeTopicToPreviousInHistory: ) ) {
	return [_contentsView canGoBack];
    }
    else if( [anItem action] == @selector( changeTopicToNextInHistory: ) ) {
	return [_contentsView canGoForward];
    }
    else if( [anItem action] == @selector( makeTextSmaller: ) ) {
	return [_contentsView canMakeTextSmaller];
    }
    else if( [anItem action] == @selector( makeTextBigger: ) ) {
	return [_contentsView canMakeTextLarger];
    }
    
    return YES;
}

#pragma mark NSResponder

- (void)keyDown:(NSEvent *)theEvent
{
    if( [theEvent modifierFlags] & NSCommandKeyMask ) {
	NSString *keyString = [theEvent charactersIgnoringModifiers];
//	NSLog( @"CHMWindowController:keyDown %@", [keyString description] );
	
	switch( [keyString characterAtIndex:0] ) {
	    case NSLeftArrowFunctionKey:
                if( [_contentsView canGoBack] ) {
                    [_contentsView goBack];
                    return;
                }
                break;
		
	    case NSRightArrowFunctionKey:
                if( [_contentsView canGoForward] ) {
                    [_contentsView goForward];
                    return;
                }
                break;
	}
    }

    [super keyDown:theEvent];
}


#pragma mark Actions

- (IBAction)toggleDrawer:(id)sender
{
    NSLog( @"First responder: %@", [[self window] firstResponder] );
    [_drawer toggle:self];
}

- (IBAction)changeTopicWithSelectedRow:(id)sender
{
    int selectedRow = [_tocView selectedRow];
    
    if( selectedRow >= 0 ) {
	CHMTopic *topic = [_tocView itemAtRow:selectedRow];
	NSURL *location = [topic location];
	
	if( location ) {
	    [[_contentsView mainFrame] loadRequest:[NSURLRequest requestWithURL:location]];
	}
    }
    
    [[self window] makeFirstResponder:self];
}

- (IBAction)makeTextBigger:(id)sender
{
	[ _contentsView makeTextLarger:sender ];
}

- (IBAction)makeTextSmaller:(id)sender
{
	[ _contentsView makeTextSmaller:sender ];
}

- (IBAction)changeTopicToPreviousInHistory:(id)sender
{
	[ _contentsView goBack ];
}

- (IBAction)changeTopicToNextInHistory:(id)sender
{
	[ _contentsView goForward ];
}

- (void)printDocument:(id)sender {
    // Obtain a custom view that will be printed
    NSView *docView = [[[_contentsView mainFrame] frameView] documentView];
    
    // Construct the print operation and setup Print panel
    NSPrintOperation *op = [NSPrintOperation printOperationWithView:docView
                                                          printInfo:[[self document] printInfo]];
				
    [op setShowPanels:YES];

    // Run operation, which shows the Print panel if showPanels was YES
    [[self document] runModalPrintOperation:op
                                   delegate:nil
                             didRunSelector:NULL
                                contextInfo:NULL];
}

#pragma mark Toolbar related methods

- (void)setupToolbar
{
    NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier:@"mainToolbar"] autorelease];

    [toolbar setDelegate:self];
    [toolbar setAllowsUserCustomization:YES];
    [toolbar setAutosavesConfiguration:YES];
    [[self window ] setToolbar:toolbar];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
    return [NSArray arrayWithObjects:
        DRAWER_TOGGLE_TOOL_ID,
        SMALLER_TEXT_TOOL_ID,
        BIGGER_TEXT_TOOL_ID,
//        HISTORY_TOOL_ID,
        NSToolbarPrintItemIdentifier,
        NSToolbarSeparatorItemIdentifier,
        NSToolbarSpaceItemIdentifier,
        NSToolbarFlexibleSpaceItemIdentifier,
        NSToolbarCustomizeToolbarItemIdentifier,
        nil
        ];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
    return [NSArray arrayWithObjects:
        DRAWER_TOGGLE_TOOL_ID,
        SMALLER_TEXT_TOOL_ID,
        BIGGER_TEXT_TOOL_ID,
        NSToolbarFlexibleSpaceItemIdentifier,
        nil
        ];
}


- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar
     itemForItemIdentifier:(NSString *)itemIdentifier
 willBeInsertedIntoToolbar:(BOOL)flag
{
    NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
    
    if ( [itemIdentifier isEqualToString:DRAWER_TOGGLE_TOOL_ID] ) {
        [item setLabel:NSLocalizedString( DRAWER_TOGGLE_TOOL_ID, nil )];
        [item setPaletteLabel:[item label]];
        [item setImage:[NSImage imageNamed:@"toolbar-drawer"]];
        [item setTarget:self];
        [item setAction:@selector(toggleDrawer:)];
    }
    else if ( [itemIdentifier isEqualToString:SMALLER_TEXT_TOOL_ID] ) {
        [item setLabel:NSLocalizedString( SMALLER_TEXT_TOOL_ID, nil )];
        [item setPaletteLabel:[item label]];
        [item setImage:[NSImage imageNamed:@"toolbar-smaller"]];
        [item setTarget:self];
        [item setAction:@selector(makeTextSmaller:)];
    }
    else if ( [itemIdentifier isEqualToString:BIGGER_TEXT_TOOL_ID] ) {
        [item setLabel:NSLocalizedString( BIGGER_TEXT_TOOL_ID, nil )];
        [item setPaletteLabel:[item label]];
        [item setImage:[NSImage imageNamed:@"toolbar-bigger"]];
        [item setTarget:self];
        [item setAction:@selector(makeTextBigger:)];
    }
    else if ( [itemIdentifier isEqualToString:HISTORY_TOOL_ID] ) {
        [_historyToolbarItemView setLabel:nil forSegment:0];
        [_historyToolbarItemView setLabel:nil forSegment:1];
        //[_historyToolbarItemView sizeToFit];
        NSRect frame = [_historyToolbarItemView frame];
        [item setLabel:NSLocalizedString( HISTORY_TOOL_ID, nil )];
        [item setView:_historyToolbarItemView];
        [item setMinSize:frame.size];
        [item setMaxSize:frame.size];
//        [item setTarget:self];
//        [item setAction:@selector(makeTextBigger:)];
    }
    
    
    return [item autorelease];
}

-(BOOL)validateToolbarItem:(NSToolbarItem*)toolbarItem
{
    NSString *itemIdentifier = [toolbarItem itemIdentifier];
    
    if ( [itemIdentifier isEqualToString:SMALLER_TEXT_TOOL_ID] ) {
	return [_contentsView canMakeTextSmaller];
    }
    else if ( [itemIdentifier isEqualToString:BIGGER_TEXT_TOOL_ID] ) {
	return [_contentsView canMakeTextLarger];
    }
    
    return YES;
}


#ifdef DEBUG_MODEX

- (BOOL) respondsToSelector: (SEL) aSelector
{
    BOOL result = [super respondsToSelector: aSelector];

    if( !result ) {
        NSLog( @"Tested for selector %s", (char *) aSelector );
    }

    return result;
}

#endif

@end
