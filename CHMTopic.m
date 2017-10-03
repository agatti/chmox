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

#import "CHMTopic.h"

@interface CHMTopic ()

@property(nonnull, strong, nonatomic) NSMutableArray *subTopics;

@end

@implementation CHMTopic

#pragma mark Lifecycle

- (nonnull instancetype)initWithName:(nonnull NSString *)name
                         andLocation:(nonnull NSURL *)location {
  if (self = [super init]) {
    _name = name;
    _location = location;
    _subTopics = [NSMutableArray new];
  }

  return self;
}

#pragma mark Accessors

- (NSUInteger)countOfSubTopics {
  return self.subTopics.count;
}

- (nonnull CHMTopic *)objectInSubTopicsAtIndex:(NSUInteger)index {
  return self.subTopics[index];
}

#pragma mark Mutators

- (void)addObject:(nonnull CHMTopic *)topic {
  [self.subTopics addObject:topic];
}

@end
