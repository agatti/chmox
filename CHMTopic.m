//
// Chmox a CHM file viewer for Mac OS X
// Copyright (c) 2004 StŽphane Boisson.
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

@property (strong, nonatomic) NSMutableArray *subTopics;

@end

@implementation CHMTopic

#pragma mark Lifecycle

- (instancetype)initWithName:(NSString *)topicName location:(NSURL *)topicLocation
{
    if( self = [super init] ) {
        _name = topicName;
        _location = topicLocation;
        _subTopics = nil;
    }
    
    return self;
}

- copyWithZone:(NSZone *)zone {
    CHMTopic *other = [[CHMTopic allocWithZone: zone] initWithName:_name location:_location];

    if(self.subTopics ) {
    other->_subTopics = _subTopics;
    }
    
    return other;
}



#pragma mark Accessors

- (NSString *)description
{
    return [NSString stringWithFormat:@"<CHMTopic:'%@',%@>", _name, _location];
}

- (unsigned int)countOfSubTopics
{
    return _subTopics? _subTopics.count : 0;
}


- (CHMTopic *)objectInSubTopicsAtIndex:(unsigned int)theIndex
{
    return _subTopics? _subTopics[theIndex] : nil;
}

#pragma mark Mutators

- (void)addObject:(CHMTopic *)topic
{
    if( !_subTopics ) {
        _subTopics = [[NSMutableArray alloc] init];
    }
    
    [_subTopics addObject:topic];
}

- (void)insertObject:(CHMTopic *)topic inSubTopicsAtIndex:(unsigned int)theIndex
{
    if( !_subTopics ) {
        _subTopics = [[NSMutableArray alloc] init];
    }
    
    [_subTopics insertObject:topic atIndex:theIndex];
}

- (void)removeObjectFromSubTopicsAtIndex:(unsigned int)theIndex
{
    if( _subTopics ) {
    [_subTopics removeObjectAtIndex:theIndex];
    }
}


@end
