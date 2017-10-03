//
// Chmox a CHM file viewer for Mac OS X
// Copyright (c) 2004 Stéphane Boisson.
// Copyright (c) 2017 Alessandro Gatti.
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

@import WebKit;

#import "CHMWindowController.h"
#import "CHMDocument.h"
#import "CHMTableOfContents.h"
#import "CHMTopic.h"
#import "CHMURLProtocol.h"

@interface CHMWindowController () <NSOutlineViewDelegate, NSToolbarDelegate,
                                   WebUIDelegate, WebPolicyDelegate>

@property(weak) IBOutlet NSOutlineView *tableOfContents;
@property(weak) IBOutlet WebView *webView;
@property(weak) IBOutlet NSToolbar *toolbar;
@property(weak) IBOutlet NSToolbarItem *backToolbarItem;
@property(weak) IBOutlet NSToolbarItem *forwardToolbarItem;
@property(weak) IBOutlet NSToolbarItem *smallerFontToolbarItem;
@property(weak) IBOutlet NSToolbarItem *biggerFontToolbarItem;

- (IBAction)makeTextSmaller:(id)sender;
- (IBAction)makeTextBigger:(id)sender;
- (IBAction)changeTopicToPreviousInHistory:(id)sender;
- (IBAction)changeTopicToNextInHistory:(id)sender;
- (IBAction)printDocument:(id)sender;
- (IBAction)changeTopicWithSelectedRow:(id)sender;

- (void)updateToolTipRects;

@end

@implementation CHMWindowController

#pragma mark NSWindowController overridden method

- (void)windowDidLoad {
  CHMDocument *document = (CHMDocument *)self.document;
  NSURLRequest *request =
      [NSURLRequest requestWithURL:document.currentLocation];
  [self.webView.mainFrame loadRequest:request];

  self.windowFrameAutosaveName = document.uniqueId;
  [self setShouldCloseDocument:YES];

  self.tableOfContents.delegate = self;
  self.tableOfContents.dataSource = document.tableOfContents;
  self.tableOfContents.autoresizesOutlineColumn = NO;

  self.backToolbarItem.enabled = NO;
  self.forwardToolbarItem.enabled = NO;

  self.biggerFontToolbarItem.enabled = self.webView.canMakeTextLarger;
  self.smallerFontToolbarItem.enabled = self.webView.canMakeTextSmaller;

  [self updateToolTipRects];
}

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName {
  NSString *windowTitle = [self.document title];
  return windowTitle ? windowTitle : displayName;
}

#pragma mark WebPolicyDelegate

- (void)webView:(WebView *)sender
    decidePolicyForNavigationAction:(NSDictionary *)actionInformation
                            request:(NSURLRequest *)request
                              frame:(WebFrame *)frame
                   decisionListener:(id<WebPolicyDecisionListener>)listener {
  if ([CHMURLProtocol canHandleURL:request.URL]) {
    [listener use];
  } else {
    [NSWorkspace.sharedWorkspace openURL:request.URL];
    [listener ignore];
  }
}

// Open external URLs in new window in external viewer
- (void)webView:(WebView *)sender
    decidePolicyForNewWindowAction:(NSDictionary *)actionInformation
                           request:(NSURLRequest *)request
                      newFrameName:(NSString *)frameName
                  decisionListener:(id<WebPolicyDecisionListener>)listener {
  if ([CHMURLProtocol canHandleURL:request.URL]) {
    [listener use];
  } else {
    [NSWorkspace.sharedWorkspace openURL:request.URL];
    [listener ignore];
  }
}

#pragma mark WebUIDelegate

- (NSArray *)webView:(WebView *)sender
    contextMenuItemsForElement:(NSDictionary *)element
              defaultMenuItems:(NSArray *)defaultMenuItems {
  NSURL *link = element[WebElementLinkURLKey];

  return link && [CHMURLProtocol canHandleURL:link] ? nil : defaultMenuItems;
}

- (void)webView:(WebView *)sender
    mouseDidMoveOverElement:(NSDictionary *)elementInformation
              modifierFlags:(NSUInteger)modifierFlags {
}

#pragma mark NSToolTipOwner

- (NSString *)view:(NSView *)view
    stringForToolTip:(NSToolTipTag)tag
               point:(NSPoint)point
            userData:(void *)userData {
  if (view == self.tableOfContents) {
    NSInteger row = [self.tableOfContents rowAtPoint:point];

    if (row >= 0) {
      return [[self.tableOfContents itemAtRow:row] name];
    }
  }

  return nil;
}

- (void)updateToolTipRects {
  [self.tableOfContents removeAllToolTips];
  NSRange range =
      [self.tableOfContents rowsInRect:self.tableOfContents.visibleRect];

  for (NSInteger i = range.location; i < NSMaxRange(range); ++i) {
    [self.tableOfContents addToolTipRect:[self.tableOfContents rectOfRow:i]
                                   owner:self
                                userData:NULL];
  }
}

#pragma mark NSResponder

- (void)keyDown:(NSEvent *)theEvent {
  if (theEvent.modifierFlags & NSCommandKeyMask) {
    NSString *keyString = theEvent.charactersIgnoringModifiers;

    switch ([keyString characterAtIndex:0]) {
    case NSLeftArrowFunctionKey:
      if (self.webView.canGoBack) {
        [self.webView goBack];
      }
      break;

    case NSRightArrowFunctionKey:
      if (self.webView.canGoForward) {
        [self.webView goForward];
      }
      break;
    default:
      break;
    }
  }

  self.backToolbarItem.enabled = self.webView.canGoBack;
  self.forwardToolbarItem.enabled = self.webView.canGoForward;

  [super keyDown:theEvent];
}

#pragma mark Actions

- (IBAction)changeTopicWithSelectedRow:(id)sender {
  NSInteger selectedRow = self.tableOfContents.selectedRow;

  if (selectedRow >= 0) {
    CHMTopic *topic = [self.tableOfContents itemAtRow:selectedRow];
    NSURL *location = topic.location;

    if (location) {
      [self.webView.mainFrame
          loadRequest:[NSURLRequest requestWithURL:location]];
      self.backToolbarItem.enabled = self.webView.canGoBack;
      self.forwardToolbarItem.enabled = self.webView.canGoForward;
    }
  }

  [self.window makeFirstResponder:self];
}

- (IBAction)makeTextBigger:(id)sender {
  [self.webView makeTextLarger:sender];
  self.biggerFontToolbarItem.enabled = self.webView.canMakeTextLarger;
  self.smallerFontToolbarItem.enabled = self.webView.canMakeTextSmaller;
}

- (IBAction)makeTextSmaller:(id)sender {
  [self.webView makeTextSmaller:sender];
  self.biggerFontToolbarItem.enabled = self.webView.canMakeTextLarger;
  self.smallerFontToolbarItem.enabled = self.webView.canMakeTextSmaller;
}

- (IBAction)changeTopicToPreviousInHistory:(id)sender {
  [self.webView goBack];
  self.backToolbarItem.enabled = self.webView.canGoBack;
  self.forwardToolbarItem.enabled = self.webView.canGoForward;
}

- (IBAction)changeTopicToNextInHistory:(id)sender {
  [self.webView goForward];
  self.backToolbarItem.enabled = self.webView.canGoBack;
  self.forwardToolbarItem.enabled = self.webView.canGoForward;
}

- (IBAction)printDocument:(id)sender {
  // Obtain a custom view that will be printed
  NSView *docView = self.webView.mainFrame.frameView.documentView;

  // Construct the print operation and setup Print panel
  NSPrintOperation *operation =
      [NSPrintOperation printOperationWithView:docView
                                     printInfo:[self.document printInfo]];
  operation.showsPrintPanel = YES;

  // Run operation, which shows the Print panel if showPanels was YES
  [self.document runModalPrintOperation:operation
                               delegate:nil
                         didRunSelector:NULL
                            contextInfo:NULL];
}

@end
