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

#import "CHMDocument.h"
#import "CHMContainer.h"
#import "CHMTableOfContents.h"
#import "CHMURLProtocol.h"
#import "CHMWindowController.h"

#pragma clang diagnostic push
#pragma ide diagnostic ignored "OCUnusedClassInspection"

@interface CHMDocument ()

@property(strong, nonatomic) CHMContainer *container;

@end

@implementation CHMDocument

- (instancetype)init {
  if (self = [super init]) {
    _container = nil;
  }

  return self;
}

- (void)dealloc {
  if (self.container) {
    [CHMURLProtocol unregisterContainer:self.container];
  }
}

- (void)makeWindowControllers {
  [self addWindowController:[[CHMWindowController alloc]
                                initWithWindowNibName:@"CHMDocument"]];
}

- (BOOL)readFromURL:(NSURL *)url
             ofType:(NSString *)typeName
              error:(NSError *_Nullable __autoreleasing *)outError {
  self.container = [CHMContainer containerWithContentsOfURL:url];
  if (self.container == nil) {
    return NO;
  }

  [CHMURLProtocol registerContainer:self.container];
  self.tableOfContents =
      [[CHMTableOfContents alloc] initWithContainer:self.container];

  return YES;
}

- (NSData *)dataOfType:(NSString *)typeName
                 error:(NSError *_Nullable __autoreleasing *)outError {
  return nil;
}

- (NSString *)title {
  return self.container.title;
}

- (NSURL *)currentLocation {
  return [CHMURLProtocol URLWithPath:self.container.homePath
                         inContainer:self.container];
}

- (NSString *)uniqueId {
  return self.container.uniqueId;
}

@end

#pragma clang diagnostic pop
