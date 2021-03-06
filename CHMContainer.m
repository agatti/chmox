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

static inline NSString *_Nonnull readString(NSData *_Nonnull data,
                                            unsigned long offset);
static inline NSString *_Nonnull readTrimmedString(NSData *_Nonnull data,
                                                   unsigned long offset);

typedef NS_ENUM(uint16_t, CHMObject) {
  CHMObjectTableOfContentsPath = 0,
  CHMObjectIndexPath,
  CHMObjectHomePagePath,
  CHMObjectTitle,
  CHMObjectSystem,
  CHMObjectDefaultWindow,
  CHMObjectCompiledFile,
  CHMObjectCompiler = 9,
  CHMObjectTimestamp,
  CHMObjectInformationTypesCount = 12,
  CHMObjectDefaultFont = 16
};

@interface CHMContainer ()

- (instancetype)initWithContentsOfURL:(nonnull NSURL *)url
    NS_DESIGNATED_INITIALIZER;

- (BOOL)loadMetadata;

@end

@implementation CHMContainer

+ (nullable instancetype)containerWithContentsOfURL:(nonnull NSURL *)url {
  return [[CHMContainer alloc] initWithContentsOfURL:url];
}

- (nullable instancetype)initWithContentsOfURL:(nonnull NSURL *)url {
  if (self = [super init]) {
    _handle = chm_open(url.fileSystemRepresentation);
    if (!_handle) {
      return nil;
    }

    if (![self loadMetadata]) {
      chm_close(_handle);
      return nil;
    }
  }

  return self;
}

- (void)dealloc {
  if (self.handle) {
    chm_close(self.handle);
  }
}

NSString *_Nonnull readString(NSData *_Nonnull data, unsigned long offset) {
  return @((const char *)data.bytes + offset);
}

NSString *_Nonnull readTrimmedString(NSData *_Nonnull data,
                                     unsigned long offset) {
  const char *stringData = (const char *)data.bytes + offset;
  return [[NSMutableString stringWithUTF8String:stringData]
      stringByTrimmingCharactersInSet:[NSCharacterSet
                                          whitespaceAndNewlineCharacterSet]];
}

- (BOOL)hasObjectWithPath:(nonnull NSString *)path {
  struct chmUnitInfo info;
  return chm_resolve_object(self.handle, path.UTF8String, &info) ==
         CHM_RESOLVE_SUCCESS;
}

- (nullable NSData *)dataWithContentsOfObject:(nullable NSString *)path {
  if (!path) {
    return nil;
  }

  if ([path hasPrefix:@"/"]) {
    if ([path hasPrefix:@"///"]) {
      path = [path substringFromIndex:2];
    }
  } else {
    path = [NSString stringWithFormat:@"/%@", path];
  }

  struct chmUnitInfo info;
  if (chm_resolve_object(_handle, path.UTF8String, &info) !=
      CHM_RESOLVE_SUCCESS) {
    return nil;
  }

  void *buffer = malloc(info.length);
  if (!buffer) {
    return nil;
  }

  if (!chm_retrieve_object(_handle, &info, buffer, 0, info.length)) {
    free(buffer);
    return nil;
  }

  return [NSData dataWithBytesNoCopy:buffer length:info.length];
}

- (nullable NSData *)dataWithTableOfContents {
  return [self dataWithContentsOfObject:self.tocPath];
}

- (BOOL)loadMetadata {
  NSData *windowsData = [self dataWithContentsOfObject:@"/#WINDOWS"];
  NSData *stringsData = [self dataWithContentsOfObject:@"/#STRINGS"];

  if (windowsData && stringsData) {
    const uint32_t entryCount = OSReadLittleInt32(windowsData.bytes, 0);
    const uint32_t entrySize = OSReadLittleInt32(windowsData.bytes, 4);

    for (int entryIndex = 0; entryIndex < entryCount; ++entryIndex) {
      unsigned long entryOffset = 8 + (entryIndex * entrySize);

      if (self.title.length == 0) {
        self.title = readTrimmedString(
            stringsData,
            OSReadLittleInt32(windowsData.bytes, entryOffset + 0x14));
      }

      if (self.tocPath.length == 0) {
        self.tocPath =
            readString(stringsData, OSReadLittleInt32(windowsData.bytes,
                                                      entryOffset + 0x60));
      }

      if (self.indexPath.length == 0) {
        self.indexPath =
            readString(stringsData, OSReadLittleInt32(windowsData.bytes,
                                                      entryOffset + 0x64));
      }

      if (self.homePath.length == 0) {
        self.homePath =
            readString(stringsData, OSReadLittleInt32(windowsData.bytes,
                                                      entryOffset + 0x68));
      }
    }
  }

  NSData *systemData = [self dataWithContentsOfObject:@"/#SYSTEM"];
  if (systemData == nil) {
    return NO;
  }

  NSUInteger maxOffset = systemData.length;
  for (unsigned int offset = 0; offset < maxOffset;
       offset += OSReadLittleInt16(systemData.bytes, offset + 2) + 4) {
    switch (OSReadLittleInt16(systemData.bytes, offset)) {
    case CHMObjectTableOfContentsPath:
      if (self.tocPath.length == 0) {
        self.tocPath = readString(systemData, offset + 4);
      }
      break;

    case CHMObjectIndexPath:
      if (self.indexPath.length == 0) {
        self.indexPath = readString(systemData, offset + 4);
      }
      break;

    case CHMObjectHomePagePath:
      if (self.homePath.length == 0) {
        self.homePath = readString(systemData, offset + 4);
      }
      break;

    case CHMObjectTitle:
      if (self.title.length == 0) {
        self.title = readTrimmedString(systemData, offset + 4);
      }
      break;

    case CHMObjectSystem:
    case CHMObjectDefaultWindow:
    case CHMObjectCompiledFile:
    case CHMObjectCompiler:
    case CHMObjectTimestamp:
    case CHMObjectInformationTypesCount:
    case CHMObjectDefaultFont:
    default:
      break;
    }
  }

  unsigned char digest[CC_SHA1_DIGEST_LENGTH];
  CC_SHA1(systemData.bytes, (CC_LONG)systemData.length, digest);
  unsigned int *ptr = (unsigned int *)digest;
  self.uniqueId = [[NSString alloc]
      initWithFormat:@"%x%x%x%x%x", ptr[0], ptr[1], ptr[2], ptr[3], ptr[4]];

  if (self.title.length == 0) {
    self.title = nil;
  }

  if (!self.homePath) {
    self.homePath = [self findHomeForPath:@"/"];
  }

  return YES;
}

- (nonnull NSString *)findHomeForPath:(nonnull NSString *)basePath {
  NSString *base = [basePath hasSuffix:@"/"]
                       ? basePath
                       : [basePath stringByAppendingString:@"/"];

  NSString *indexPath = [NSString stringWithFormat:@"%@index.htm", base];
  if ([self hasObjectWithPath:indexPath]) {
    return indexPath;
  }

  NSString *defaultPath = [NSString stringWithFormat:@"%@default.html", base];
  if ([self hasObjectWithPath:defaultPath]) {
    return defaultPath;
  }

  return indexPath;
}

@end
