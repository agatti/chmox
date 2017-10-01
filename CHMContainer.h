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

struct chmFile;

@interface CHMContainer : NSObject

@property (assign, nonatomic) struct chmFile *handle;
@property (strong, nonatomic) NSString *uniqueId;
@property (strong, nonatomic) NSString *path;
@property (strong, nonatomic) NSString *title;
@property (strong, nonatomic) NSString *homePath;
@property (strong, nonatomic) NSString *tocPath;
@property (strong, nonatomic) NSString *indexPath;

+ (id)containerWithContentsOfFile:(NSString *)path;

- (id)initWithContentsOfFile:(NSString *)path;

- (bool)hasObjectWithPath: (NSString *)path;
- (NSData *)dataWithContentsOfObject: (NSString *)objectPath;
- (NSString *)stringWithContentsOfObject: (NSString *)objectPath;
- (NSData *)dataWithTableOfContents;

- (BOOL)loadMetadata;
- (NSString *)findHomeForPath: (NSString *)basePath;

@end
