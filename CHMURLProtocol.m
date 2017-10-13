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

#import "CHMURLProtocol.h"
#import "CHMContainer.h"

static NSMutableDictionary *kContainers = nil;
static NSMutableDictionary *kBaseURLs = nil;

@implementation CHMURLProtocol

- (instancetype)initWithRequest:(NSURLRequest *)request
                 cachedResponse:(NSCachedURLResponse *)cachedResponse
                         client:(id<NSURLProtocolClient>)client {
  return (CHMURLProtocol *)[super initWithRequest:request
                                   cachedResponse:cachedResponse
                                           client:client];
}

+ (void)registerContainer:(nonnull CHMContainer *)container {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    kContainers = [NSMutableDictionary new];
    kBaseURLs = [NSMutableDictionary new];
  });

  NSString *key = container.uniqueId;
  NSURL *baseURL = [NSURL
      URLWithString:[NSString stringWithFormat:@"chmox-internal://%@/", key]];
  kContainers[key] = container;
  kBaseURLs[key] = baseURL;
}

+ (nullable CHMContainer *)containerForUniqueId:(nonnull NSString *)uniqueId {
  return kContainers[uniqueId];
}

+ (void)unregisterContainer:(nonnull CHMContainer *)container {
  NSString *key = container.uniqueId;

  [kContainers removeObjectForKey:key];
  [kBaseURLs removeObjectForKey:key];
}

+ (nullable NSURL *)URLWithPath:(nonnull NSString *)path
                    inContainer:(nonnull CHMContainer *)container {
  NSURL *baseURL = kBaseURLs[container.uniqueId];
  NSURL *url = [NSURL URLWithString:path relativeToURL:baseURL];

  if (baseURL && url == nil) {
    // Something is wrong, perhaps path is not well-formed. Try percent-
    // escaping characters. It's not clear what encoding should be used,
    // but for now let's just use Latin1.

    url = [NSURL
        URLWithString:[path stringByAddingPercentEncodingWithAllowedCharacters:
                                [NSCharacterSet
                                    characterSetWithCharactersInString:@"%#"]]
        relativeToURL:baseURL];
  }

  return url;
}

+ (BOOL)canHandleURL:(nonnull NSURL *)anURL {
  return [anURL.scheme isEqualToString:@"chmox-internal"];
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
  return [self canHandleURL:request.URL];
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
  return request;
}

- (void)startLoading {
  NSURL *url = self.request.URL;

  CHMContainer *container = [CHMURLProtocol containerForUniqueId:url.host];

  if (!container) {
    [self.client URLProtocol:self
            didFailWithError:[NSError errorWithDomain:NSURLErrorDomain
                                                 code:0
                                             userInfo:nil]];
    return;
  }

  NSData *data;

  if (url.parameterString) {
    data = [container
        dataWithContentsOfObject:[NSString
                                     stringWithFormat:@"%@;%@", url.path,
                                                      url.parameterString]];
  } else {
    data = [container dataWithContentsOfObject:url.path];
  }

  if (!data) {
    [self.client URLProtocol:self
            didFailWithError:[NSError errorWithDomain:NSURLErrorDomain
                                                 code:0
                                             userInfo:nil]];
    return;
  }

  NSURLResponse *response =
      [[NSURLResponse alloc] initWithURL:self.request.URL
                                MIMEType:@"application/octet-stream"
                   expectedContentLength:data.length
                        textEncodingName:nil];
  [self.client URLProtocol:self
        didReceiveResponse:response
        cacheStoragePolicy:NSURLCacheStorageNotAllowed];

  [self.client URLProtocol:self didLoadData:data];
  [self.client URLProtocolDidFinishLoading:self];
}

- (void)stopLoading {
}

@end
