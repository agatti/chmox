//
// Chmox a CHM file viewer for Mac OS X
// Copyright (c) 2004 Stéphane Boisson.
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
// $Revision: 1.5 $
//

#import "CHMURLProtocol.h"
#import "CHMContainer.h"

@implementation CHMURLProtocol

#pragma mark Lifecycle

-(id)initWithRequest:(NSURLRequest *)request
      cachedResponse:(NSCachedURLResponse *)cachedResponse
	      client:(id <NSURLProtocolClient>)client
{
    return [super initWithRequest:request cachedResponse:cachedResponse client:client];
}

#pragma mark CHM URL utils

static NSMutableDictionary *_containers = nil;
static NSMutableDictionary *_baseURLs = nil;

+ (void)registerContainer:(CHMContainer *)container
{
    NSString *key = [container uniqueId];

    if( !_containers ) {
	_containers = [[NSMutableDictionary alloc] init];
	_baseURLs = [[NSMutableDictionary alloc] init];
    }
    
    NSURL *baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"chmox-internal://%@/", key]];
    [_containers setObject:container forKey:key];
    [_baseURLs setObject:baseURL forKey:key];
}

+ (CHMContainer *)containerForUniqueId:(NSString *)uniqueId
{
    return _containers? [_containers objectForKey:uniqueId] : nil;
}

+ (void)unregisterContainer:(CHMContainer *)container
{
    NSString *key = [container uniqueId];

    [_containers removeObjectForKey:key];
    [_baseURLs removeObjectForKey:key];
}

+ (NSURL *)URLWithPath:(NSString *)path inContainer:(CHMContainer *)container
{
    NSURL *baseURL = [_baseURLs objectForKey:[container uniqueId]];
    NSURL *url = [NSURL URLWithString:path relativeToURL:baseURL];
    
    if( baseURL && url == nil ) {
	// Something is wrong, perhaps path is not well-formed. Try percent-
	// escaping characters. It's not clear what encoding should be used,
	// but for now let's just use Latin1.
	CFStringRef str = CFURLCreateStringByAddingPercentEscapes(
            nil,                                // allocator
            (CFStringRef)path,                  // <#CFStringRef originalString#>
	    (CFStringRef)@"%#",                 // <#CFStringRef charactersToLeaveUnescaped#>
	    nil,                                // <#CFStringRef legalURLCharactersToBeEscaped#>,
	    kCFStringEncodingWindowsLatin1      //<#CFStringEncoding encoding#>
        );
        
        url = [NSURL URLWithString:(NSString*)str relativeToURL:baseURL];
    }
    
    return url;
}

+ (BOOL)canHandleURL:(NSURL *)anURL 
{
    return [[anURL scheme] isEqualToString:@"chmox-internal"];
}

#pragma mark NSURLProtocol overriding
+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    if( [self canHandleURL:[request URL]] ) {
	return YES;
    }
    else {
	NSLog( @"CHMURLProtocol cannot handle %@", request );
	return NO;
    }
}


+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    return request;
}


-(void)startLoading
{
    DEBUG_OUTPUT( @"CHMURLProtocol:startLoading %@", [self request] );

    NSURL *url = [[self request] URL];

/*
 NSString *rawPath = [[[self request] URL] path];
 NSLog( @"rawPath: %@", rawPath );
 NSRange separator = [rawPath rangeOfString:@"::/"];
 NSString *containerPath = [rawPath substringToIndex:separator.location];
 NSString *contentsPath = [rawPath substringFromIndex:( separator.location + 2 )];
   
 NSLog( @"containerPath: %@", containerPath );
 NSLog( @"contentsPath: %@", contentsPath );
   
 CHMContainer *container = [CHMContainer containerWithContentsOfFile:containerPath];
 */

    CHMContainer *container = [CHMURLProtocol containerForUniqueId:[url host]];
	    
    if( !container ) {
	[[self client] URLProtocol:self didFailWithError:[NSError errorWithDomain:NSURLErrorDomain code:0 userInfo:nil]];
	return;
    }

    NSData *data;
    
    if( [url parameterString] ) {
        data = [container dataWithContentsOfObject:[NSString stringWithFormat:@"%@;%@", [url path], [url parameterString]] ];
    }
    else {
        data = [container dataWithContentsOfObject:[url path]];
    }
    
    if( !data ) {
	[[self client] URLProtocol:self didFailWithError:[NSError errorWithDomain:NSURLErrorDomain code:0 userInfo:nil]];
	return;
    }
    
    NSURLResponse *response = [[NSURLResponse alloc] initWithURL: [[self request] URL]
							MIMEType:@"application/octet-stream"
					   expectedContentLength:[data length]
						textEncodingName:nil];
    [[self client] URLProtocol:self     
	    didReceiveResponse:response 
	    cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    
    [[self client] URLProtocol:self didLoadData:data];
    [[self client] URLProtocolDidFinishLoading:self];

    [response release];
}


-(void)stopLoading
{
//    NSLog( @"CHMURLProtocol:stopLoading" );
}

/*
-(NSCachedURLResponse *)cachedResponse
{
}
*/

@end
