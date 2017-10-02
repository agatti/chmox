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

#import <Foundation/Foundation.h>

@interface CHMTopic : NSObject

@property(nonnull, strong, nonatomic) NSString *name;
@property(nonnull, strong, nonatomic) NSURL *location;

- (nullable instancetype)init
    __attribute__((unavailable("You cannot create a foo instance through init "
                               "- please use initWithName:location:")));

- (nonnull instancetype)initWithName:(nonnull NSString *)topicName
                         andLocation:(nonnull NSURL *)topicLocation
    NS_DESIGNATED_INITIALIZER;

@property(nonatomic, readonly) NSUInteger countOfSubTopics;
- (nonnull CHMTopic *)objectInSubTopicsAtIndex:(NSUInteger)index;

- (void)addObject:(nonnull CHMTopic *)topic;
- (void)insertObject:(CHMTopic *)topic inSubTopicsAtIndex:(NSUInteger)index;
- (void)removeObjectFromSubTopicsAtIndex:(NSUInteger)index;

@end
