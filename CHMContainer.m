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

#include <CommonCrypto/CommonCrypto.h>

#import "CHMContainer.h"
#import "chm_lib.h"

@interface CHMContainer ()

- (instancetype)initWithContentsOfFile:(NSString *__nonnull)path
    NS_DESIGNATED_INITIALIZER;

- (BOOL)loadMetadata;

@end

@implementation CHMContainer

#pragma mark Factory

+ (instancetype)containerWithContentsOfFile:(NSString *__nonnull)chmFilePath {
  return [[CHMContainer alloc] initWithContentsOfFile:chmFilePath];
}

#pragma mark Lifecycle

- (instancetype)initWithContentsOfFile:(NSString *__nonnull)chmFilePath {
  if (self = [super init]) {
    _handle = chm_open(chmFilePath.fileSystemRepresentation);
    if (!_handle)
      return nil;

    _path = chmFilePath;

    // TODO: Throw if -[loadMetadata] fails.
    [self loadMetadata];
  }

  return self;
}

- (void)dealloc {
  NSLog(@"deallocating %@", self);

  if (_handle) {
    chm_close(_handle);
  }
}

#pragma mark Basic CHM reading operations

static inline NSString *readString(NSData *data, unsigned long offset) {
  return @((const char *)data.bytes + offset);
}

static inline NSString *readTrimmedString(NSData *data, unsigned long offset) {
  const char *stringData = data.bytes + offset;
  return [[NSMutableString stringWithUTF8String:stringData]
      stringByTrimmingCharactersInSet:[NSCharacterSet
                                          whitespaceAndNewlineCharacterSet]];
}

#pragma mark CHM Object loading

- (BOOL)hasObjectWithPath:(NSString *)path {
  struct chmUnitInfo info;
  return chm_resolve_object(self.handle, path.UTF8String, &info) ==
         CHM_RESOLVE_SUCCESS;
}

- (NSData *)dataWithContentsOfObject:(NSString *)path {
  // NSLog( @"dataWithContentsOfObject: %@", path );
  if (!path) {
    return nil;
  }

  if ([path hasPrefix:@"/"]) {
    // Quick fix
    if ([path hasPrefix:@"///"]) {
      path = [path substringFromIndex:2];
    }
  } else {
    path = [NSString stringWithFormat:@"/%@", path];
  }

  struct chmUnitInfo info;
  if (chm_resolve_object(_handle, path.UTF8String, &info) !=
      CHM_RESOLVE_SUCCESS) {
    NSLog(@"Unable to find %@", path);
    return nil;
  }

  DEBUG_OUTPUT(@"Found object %@ (%qu bytes)", path, (long long)info.length);

  void *buffer = malloc(info.length);

  if (!buffer) {
    // Allocation failed
    NSLog(@"Failed to allocate %qu bytes for %@", (long long)info.length, path);
    return nil;
  }

  if (!chm_retrieve_object(_handle, &info, buffer, 0, info.length)) {
    NSLog(@"Failed to load %qu bytes for %@", (long long)info.length, path);
    free(buffer);
    return nil;
  }

  return [NSData dataWithBytesNoCopy:buffer length:info.length];
}

- (NSString *)stringWithContentsOfObject:(NSString *)objectPath {
  NSData *data = [self dataWithContentsOfObject:objectPath];
  if (data) {
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
  }

  return nil;
}

- (NSData *)dataWithTableOfContents {
  return [self dataWithContentsOfObject:_tocPath];
}

#pragma mark CHM setup

- (BOOL)loadMetadata {

  //--- Start with WINDOWS object ---
  NSData *windowsData = [self dataWithContentsOfObject:@"/#WINDOWS"];
  NSData *stringsData = [self dataWithContentsOfObject:@"/#STRINGS"];

  if (windowsData && stringsData) {
    const uint32_t entryCount = OSReadLittleInt32(windowsData.bytes, 0);
    const uint32_t entrySize = OSReadLittleInt32(windowsData.bytes, 4);
    NSLog(@"Entries: %u x %u bytes", entryCount, entrySize);

    for (int entryIndex = 0; entryIndex < entryCount; ++entryIndex) {
      unsigned long entryOffset = 8 + (entryIndex * entrySize);

      if (self.title.length == 0) {
        self.title = readTrimmedString(
            stringsData,
            OSReadLittleInt32(windowsData.bytes, entryOffset + 0x14));
        NSLog(@"Title: %@", self.title);
      }

      if (self.tocPath.length == 0) {
        self.tocPath =
            readString(stringsData, OSReadLittleInt32(windowsData.bytes,
                                                      entryOffset + 0x60));
        NSLog(@"Table of contents: %@", self.tocPath);
      }

      if (self.indexPath.length == 0) {
        self.indexPath =
            readString(stringsData, OSReadLittleInt32(windowsData.bytes,
                                                      entryOffset + 0x64));
        NSLog(@"Index: %@", self.indexPath);
      }

      if (self.homePath.length == 0) {
        self.homePath =
            readString(stringsData, OSReadLittleInt32(windowsData.bytes,
                                                      entryOffset + 0x68));
        NSLog(@"Home: %@", self.homePath);
      }
    }
  }

  //--- Use SYSTEM object ---
  NSData *systemData = [self dataWithContentsOfObject:@"/#SYSTEM"];
  if (systemData == nil) {
    return NO;
  }

  NSUInteger maxOffset = systemData.length;
  for (unsigned int offset = 0; offset < maxOffset;
       offset += OSReadLittleInt16(systemData.bytes, offset + 2) + 4) {
    switch (OSReadLittleInt16(systemData.bytes, offset)) {
    // Table of contents file
    case 0:
      if (self.tocPath.length == 0) {
        self.tocPath = readString(systemData, offset + 4);
        NSLog(@"SYSTEM Table of contents: %@", self.tocPath);
      }
      break;

    // Index file
    case 1:
      if (!_indexPath || (_indexPath.length == 0)) {
        _indexPath = readString(systemData, offset + 4);
        NSLog(@"SYSTEM Index: %@", _indexPath);
      }
      break;

    // Home page
    case 2:
      if (!_homePath || (_homePath.length == 0)) {
        _homePath = readString(systemData, offset + 4);
        NSLog(@"SYSTEM Home: %@", _homePath);
      }
      break;

    // Title
    case 3:
      if (!_title || (_title.length == 0)) {
        _title = readTrimmedString(systemData, offset + 4);
        NSLog(@"SYSTEM Title: %@", _title);
      }
      break;

    // Compiled file
    case 6:
      NSLog(@"SYSTEM compiled file: %@", readString(systemData, offset + 4));
      break;

    // Compiler
    case 9:
      NSLog(@"SYSTEM Compiler: %@", readString(systemData, offset + 4));
      break;

    // Default font
    case 16:
      NSLog(@"SYSTEM Default font: %@", readString(systemData, offset + 4));
      break;

    // Other data not handled
    default:
      break;
    }
  }

  //--- Compute unique id ---

  unsigned char digest[CC_SHA1_DIGEST_LENGTH];
  CC_SHA1(systemData.bytes, (CC_LONG)systemData.length, digest);
  unsigned int *ptr = (unsigned int *)digest;
  self.uniqueId = [[NSString alloc]
      initWithFormat:@"%x%x%x%x%x", ptr[0], ptr[1], ptr[2], ptr[3], ptr[4]];
  NSLog(@"UniqueId=%@", self.uniqueId);

  // Check for empty string titles
  if (self.title.length == 0) {
    self.title = nil;
  }

  // Check for lack of index page
  if (!self.homePath) {
    self.homePath = [self findHomeForPath:@"/"];
    NSLog(@"Implicit home: %@", self.homePath);
  }

  return YES;
}

- (NSString *)findHomeForPath:(NSString *__nonnull)basePath {
  NSString *testPath;

  NSString *separator = [basePath hasSuffix:@"/"] ? @"" : @"/";
  testPath = [NSString stringWithFormat:@"%@%@index.htm", basePath, separator];
  if ([self hasObjectWithPath:testPath]) {
    return testPath;
  }

  testPath =
      [NSString stringWithFormat:@"%@%@default.html", basePath, separator];
  if ([self hasObjectWithPath:testPath]) {
    return testPath;
  }

  testPath =
      [NSString stringWithFormat:@"%@%@default.htm", basePath, separator];
  if ([self hasObjectWithPath:testPath]) {
    return testPath;
  }

  return [NSString stringWithFormat:@"%@%@index.html", basePath, separator];
}

- (BOOL)setupFromSystemObject {
  return YES;
}

@end
