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

@import Foundation;

@class CHMContainer;

@interface CHMURLProtocol : NSURLProtocol

+ (void)registerContainer:(nonnull CHMContainer *)container;
+ (void)unregisterContainer:(nonnull CHMContainer *)container;

+ (BOOL)canHandleURL:(nonnull NSURL *)anURL;
+ (nullable CHMContainer *)containerForUniqueId:(nonnull NSString *)uniqueId;
+ (nullable NSURL *)URLWithPath:(nonnull NSString *)path
                    inContainer:(nonnull CHMContainer *)container;

@end
