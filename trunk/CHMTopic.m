//
// Chmox a CHM file viewer for Mac OS X
// Copyright (c) 2004 StŽphane Boisson.
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
// $Revision: 1.4 $
//

#import "CHMTopic.h"


@implementation CHMTopic

#pragma mark Lifecycle

- (id)initWithName:(NSString *)topicName location:(NSURL *)topicLocation
{
    if( self = [super init] ) {
        _name = [topicName retain];
        _location = [topicLocation retain];
	_subTopics = nil;
    }
    
    return self;
}

- copyWithZone:(NSZone *)zone {
    CHMTopic *other = [[CHMTopic allocWithZone: zone] initWithName:_name location:_location];

    if( _subTopics ) {
	other->_subTopics = [_subTopics retain];
    }
    
    return other;
}

- (void) dealloc
{
    [_name release];
    [_location release];
    
    if( _subTopics ) {
	[_subTopics release];
    }

    [super dealloc];
}


#pragma mark Accessors

- (NSString *)description
{
    return [NSString stringWithFormat:@"<CHMTopic:'%@',%@>", _name, _location];
}


- (NSString *)name
{
    return _name;
}

- (NSURL *)location
{
    return _location;
}

- (unsigned int)countOfSubTopics
{
    return _subTopics? [_subTopics count] : 0;
}


- (CHMTopic *)objectInSubTopicsAtIndex:(unsigned int)theIndex
{
    return _subTopics? [_subTopics objectAtIndex:theIndex] : nil;
}

#pragma mark Mutators

- (void)setName:(NSString *)text
{
    if( _name != text ) {
	[_name release];
	_name = [text retain];
    }
}

- (void)setLocation:(NSURL *)URL
{
    if( _location != URL ) {
	[_location release];
	_location = [URL retain];
    }
}

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
