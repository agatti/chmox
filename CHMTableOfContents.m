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

#import "CHMTableOfContents.h"
#import "CHMContainer.h"
#import "CHMTopic.h"
#import "CHMURLProtocol.h"

#import <libxml/HTMLparser.h>

@interface CHMTableOfContents ()

@property(strong, nonatomic) CHMContainer *container;
@property(strong, nonatomic) NSMutableArray *topicStack;
@property(strong, nonatomic) CHMTopic *placeholder;
@property(strong, nonatomic) CHMTopic *lastTopic;
@property(strong, nonatomic) NSString *name;
@property(strong, nonatomic) NSString *path;

@end

@implementation CHMTableOfContents

static void createNewTopic(void *context);

static void documentDidStart(void __unused *toc);

static void documentDidEnd(void __unused *toc);

static void elementDidStart(void *toc, const xmlChar *name,
                            const xmlChar **atts);

static void elementDidEnd(void *toc, const xmlChar *name);

static htmlSAXHandler saxHandler = {
    NULL,                                   /* internalSubset */
    NULL,                                   /* isStandalone */
    NULL,                                   /* hasInternalSubset */
    NULL,                                   /* hasExternalSubset */
    NULL,                                   /* resolveEntity */
    NULL,                                   /* getEntity */
    NULL,                                   /* entityDecl */
    NULL,                                   /* notationDecl */
    NULL,                                   /* attributeDecl */
    NULL,                                   /* elementDecl */
    NULL,                                   /* unparsedEntityDecl */
    NULL,                                   /* setDocumentLocator */
    (startDocumentSAXFunc)documentDidStart, /* startDocument */
    (endDocumentSAXFunc)documentDidEnd,     /* endDocument */
    (startElementSAXFunc)elementDidStart,   /* startElement */
    (endElementSAXFunc)elementDidEnd,       /* endElement */
    NULL,                                   /* reference */
    NULL,                                   /* characters */
    NULL,                                   /* ignorableWhitespace */
    NULL,                                   /* processingInstruction */
    NULL,                                   /* comment */
    NULL,                                   /* xmlParserWarning */
    NULL,                                   /* xmlParserError */
    NULL,                                   /* xmlParserError */
    NULL,                                   /* getParameterEntity */
    NULL,                                   /* cdataBlock */
    NULL,                                   /* externalSubset */
    0,                                      /* initialized */
    NULL,                                   /* _private */
    NULL,                                   /* startElementNs */
    NULL,                                   /* endElementNs */
    NULL                                    /* serror */
};

- (nonnull instancetype)initWithContainer:(nonnull CHMContainer *)container {
  if (self = [super init]) {
    _rootTopics = [NSMutableArray new];
    _container = container;
    _topicStack = [NSMutableArray new];
    _placeholder = [CHMTopic new];

    NSData *tocData = [container dataWithTableOfContents];

    // XML_CHAR_ENCODING_NONE / XML_CHAR_ENCODING_UTF8 /
    // XML_CHAR_ENCODING_8859_1
    htmlParserCtxtPtr parser = htmlCreatePushParserCtxt(
        &saxHandler, (__bridge void *)self, tocData.bytes, (int)tocData.length,
        NULL, XML_CHAR_ENCODING_8859_1);
    htmlParseChunk(parser, tocData.bytes, 0, 1);

    htmlDocPtr doc = parser->myDoc;
    htmlFreeParserCtxt(parser);
    if (doc) {
      xmlFreeDoc(doc);
    }
  }

  return self;
}

- (void)addRootTopic:(nonnull CHMTopic *)topic {
  [self.rootTopics addObject:topic];
}

void documentDidStart(void __unused *context) {}

void documentDidEnd(void __unused *context) {}

void elementDidStart(void *context, const xmlChar *name, const xmlChar **atts) {
  CHMTableOfContents *toc = (__bridge CHMTableOfContents *)context;

  if (!strcasecmp("ul", (const char *)name)) {
    if (toc.name) {
      createNewTopic(context);
    }

    if (toc.lastTopic) {
      [toc.topicStack addObject:toc.lastTopic];
      toc.lastTopic = nil;
    } else {
      [toc.topicStack addObject:toc.placeholder];
    }

  } else if (!strcasecmp("li", (const char *)name)) {
    // Opening depth level
    toc.name = nil;
    toc.path = nil;
  } else if (!strcasecmp("param", (const char *)name) && (atts != NULL)) {
    // Topic properties
    const xmlChar *type = NULL;
    const xmlChar *value = NULL;

    for (int i = 0; atts[i] != NULL; i += 2) {
      if (!strcasecmp("name", (const char *)atts[i])) {
        type = atts[i + 1];
      } else if (!strcasecmp("value", (const char *)atts[i])) {
        value = atts[i + 1];
      }
    }

    if ((type != NULL) && (value != NULL)) {
      if (!strcasecmp("Name", (const char *)type)) {
        // Name of the topic
        toc.name = [[NSString alloc] initWithUTF8String:(const char *)value];
      } else if (!strcasecmp("Local", (const char *)type)) {
        // Path of the topic
        toc.path = [[NSString alloc] initWithUTF8String:(const char *)value];
      } else {
        // Unsupported topic property
      }
    }
  }
}

void elementDidEnd(void *context, const xmlChar *name) {
  CHMTableOfContents *toc = (__bridge CHMTableOfContents *)context;

  if (!strcasecmp("li", (const char *)name) && toc.name) {
    createNewTopic(context);
  } else if (!strcasecmp("ul", (const char *)name)) {
    if ((toc.topicStack).count > 0) {
      toc.lastTopic = (toc.topicStack)[(toc.topicStack).count - 1];
      [toc.topicStack removeLastObject];

      if (toc.lastTopic == toc.placeholder) {
        toc.lastTopic = nil;
      }
    } else {
      toc.lastTopic = nil;
    }
  }
}

void createNewTopic(void *context) {
  NSURL *location = nil;
  CHMTableOfContents *toc = (__bridge CHMTableOfContents *)context;

  if (toc.path) {
    location = [CHMURLProtocol URLWithPath:toc.path inContainer:toc.container];
  }

  toc.lastTopic = [[CHMTopic alloc] initWithName:toc.name andLocation:location];
  toc.name = nil;
  toc.path = nil;

  NSInteger level = toc.topicStack.count;

  // Add topic to its parent
  while (--level >= 0) {
    CHMTopic *parent = toc.topicStack[(NSUInteger)level];

    if (parent != toc.placeholder) {
      [parent addObject:toc.lastTopic];
      return;
    }
  }

  [toc addRootTopic:toc.lastTopic];
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView
    numberOfChildrenOfItem:(id)item {
  return item ? [item countOfSubTopics] : self.rootTopics.count;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
  return [item countOfSubTopics] > 0;
}

- (id)outlineView:(NSOutlineView *)outlineView
            child:(NSInteger)theIndex
           ofItem:(id)item {
  return item ? [item objectInSubTopicsAtIndex:(NSUInteger)theIndex]
              : self.rootTopics[(NSUInteger)theIndex];
}

- (id)outlineView:(NSOutlineView *)outlineView
    objectValueForTableColumn:(NSTableColumn *)tableColumn
                       byItem:(id)item {
  return [item name];
}

@end
