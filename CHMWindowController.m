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

typedef NS_ENUM(NSUInteger, CHMFontSizeSegmentIndex) {
  CHMFontSizeSegmentIndexBigger = 0,
  CHMFontSizeSegmentIndexSmaller
};

typedef NS_ENUM(NSUInteger, CHMNavigationSegmentIndex) {
  CHMNavigationSegmentIndexBack = 0,
  CHMNavigationSegmentIndexForward
};

@interface CHMWindowController () <NSOutlineViewDelegate, NSToolbarDelegate,
                                   WebUIDelegate, WebPolicyDelegate,
                                   NSTouchBarProvider>

@property(weak) IBOutlet NSOutlineView *tableOfContents;
@property(weak) IBOutlet WebView *webView;
@property(weak) IBOutlet NSToolbar *toolbar;
@property(weak) IBOutlet NSButton *backTouchBarButton;
@property(weak) IBOutlet NSButton *forwardTouchBarButton;
@property(weak) IBOutlet NSButton *smallerFontTouchBarButton;
@property(weak) IBOutlet NSButton *biggerFontTouchBarButton;
@property(weak) IBOutlet NSSegmentedControl *fontSizeSegmentedControl;
@property(weak) IBOutlet NSSegmentedControl *navigationSegmentedControl;
#pragma clang diagnostic push
#pragma ide diagnostic ignored "UnavailableInDeploymentTarget"
@property(strong) IBOutlet NSTouchBar *touchBarObject;
#pragma clang diagnostic pop

- (IBAction)makeTextSmaller:(id)sender;
- (IBAction)makeTextBigger:(id)sender;
- (IBAction)changeTopicToPreviousInHistory:(id)sender;
- (IBAction)changeTopicToNextInHistory:(id)sender;
- (IBAction)printDocument:(id)sender;
- (IBAction)changeTopicWithSelectedRow:(id)sender;
- (IBAction)fontSizeChangeRequest:(id)sender;
- (IBAction)navigationRequest:(id)sender;

- (void)updateToolTipRects;
- (void)updateNavigationButtons;
- (void)updateFontSizeButtons;

@end

@implementation CHMWindowController

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

  self.backTouchBarButton.enabled = NO;
  self.forwardTouchBarButton.enabled = NO;

  [self updateFontSizeButtons];

  [self updateToolTipRects];
}

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName {
  NSString *windowTitle = [self.document title];
  return windowTitle ? windowTitle : displayName;
}

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

  return NSString.string;
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

- (void)keyDown:(NSEvent *)theEvent {
  if (theEvent.modifierFlags & NSEventModifierFlagCommand) {
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

  [self updateNavigationButtons];

  [super keyDown:theEvent];
}

- (IBAction)changeTopicWithSelectedRow:(id)sender {
  NSInteger selectedRow = self.tableOfContents.selectedRow;

  if (selectedRow >= 0) {
    CHMTopic *topic = [self.tableOfContents itemAtRow:selectedRow];
    NSURL *location = topic.location;

    if (location) {
      [self.webView.mainFrame
          loadRequest:[NSURLRequest requestWithURL:location]];
      [self updateNavigationButtons];
    }
  }

  [self.window makeFirstResponder:self];
}

- (IBAction)fontSizeChangeRequest:(id)sender {
  switch (self.fontSizeSegmentedControl.selectedSegment) {
  case CHMFontSizeSegmentIndexSmaller:
    [self makeTextSmaller:self];
    break;

  case CHMFontSizeSegmentIndexBigger:
    [self makeTextBigger:self];
    break;

  default:
    break;
  }

  [self updateFontSizeButtons];
}

- (IBAction)navigationRequest:(id)sender {
  switch (self.navigationSegmentedControl.selectedSegment) {
  case CHMNavigationSegmentIndexBack:
    [self changeTopicToPreviousInHistory:self];
    break;

  case CHMNavigationSegmentIndexForward:
    [self changeTopicToNextInHistory:self];
    break;

  default:
    break;
  }

  [self updateNavigationButtons];
}

- (IBAction)makeTextBigger:(id)sender {
  [self.webView makeTextLarger:sender];
  [self updateFontSizeButtons];
}

- (IBAction)makeTextSmaller:(id)sender {
  [self.webView makeTextSmaller:sender];
  [self updateFontSizeButtons];
}

- (IBAction)changeTopicToPreviousInHistory:(id)sender {
  [self.webView goBack];
  [self updateNavigationButtons];
}

- (IBAction)changeTopicToNextInHistory:(id)sender {
  [self.webView goForward];
  [self updateNavigationButtons];
}

- (IBAction)printDocument:(id)sender {
  NSView *docView = self.webView.mainFrame.frameView.documentView;
  NSPrintOperation *operation =
      [NSPrintOperation printOperationWithView:docView
                                     printInfo:[self.document printInfo]];
  operation.showsPrintPanel = YES;
  [self.document runModalPrintOperation:operation
                               delegate:nil
                         didRunSelector:NULL
                            contextInfo:NULL];
}

- (void)updateNavigationButtons {
  [self.navigationSegmentedControl setEnabled:self.webView.canGoBack
                                   forSegment:CHMNavigationSegmentIndexBack];
  [self.navigationSegmentedControl setEnabled:self.webView.canGoForward
                                   forSegment:CHMNavigationSegmentIndexForward];
  self.backTouchBarButton.enabled = self.webView.canGoBack;
  self.forwardTouchBarButton.enabled = self.webView.canGoForward;
}

- (void)updateFontSizeButtons {
  [self.fontSizeSegmentedControl setEnabled:self.webView.canMakeTextLarger
                                 forSegment:CHMFontSizeSegmentIndexBigger];
  [self.fontSizeSegmentedControl setEnabled:self.webView.canMakeTextSmaller
                                 forSegment:CHMFontSizeSegmentIndexSmaller];

  self.biggerFontTouchBarButton.enabled = self.webView.canMakeTextLarger;
  self.smallerFontTouchBarButton.enabled = self.webView.canMakeTextSmaller;
}

#pragma clang diagnostic push
#pragma ide diagnostic ignored "UnavailableInDeploymentTarget"

- (nullable NSTouchBar *)touchBar {
  return self.touchBarObject;
}

#pragma clang diagnostic pop

@end
