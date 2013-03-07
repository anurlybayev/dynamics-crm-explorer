//
//  XMLReader.m
//  MSDynamicsCRMExplorer
//
//  Created by Akbar Nurlybayev on 2013-03-07.
//  Copyright (c) 2013 Akbar Nurlybayev. All rights reserved.
//

#import "XMLReader.h"

NSString *const kXMLReaderTextNodeKey = @"text";

@interface XMLReader ()

@property(nonatomic, retain) NSMutableArray *dictionaryStack;
@property(nonatomic, retain) NSMutableString *textInProgress;
@property(nonatomic, retain) NSError *error;

@end

@implementation XMLReader

- (void)dealloc
{
    [_dictionaryStack release];
    [_textInProgress release];
    [_error release];
    [super dealloc];
}

+ (void)parseXMLWithNSXMLParser:(NSXMLParser *)parser completionHandler:(void (^)(id, NSError *))handler
{
    XMLReader *reader = [[XMLReader alloc] init];
    reader.dictionaryStack = [[[NSMutableArray alloc] init] autorelease];
    reader.textInProgress = [[[NSMutableString alloc] init] autorelease];
    [reader.dictionaryStack addObject:[NSMutableDictionary dictionary]];
    
    parser.delegate = reader;
    parser.shouldProcessNamespaces = YES;
    BOOL success = [parser parse];
    if (success) {
        handler([reader.dictionaryStack objectAtIndex:0], nil);
    } else {
        handler(nil, [parser parserError]);
    }
    [reader release];
}

+ (void)parseXMLData:(NSData *)data completionHandler:(void (^)(id, NSError *))handler
{
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
    [XMLReader parseXMLWithNSXMLParser:parser completionHandler:handler];
    [parser release];
}

+ (void)parseXMLString:(NSString *)xml completionHandler:(void (^)(id, NSError *))handler
{
    NSData *data = [xml dataUsingEncoding:NSUTF8StringEncoding];
    return [XMLReader parseXMLData:data completionHandler:handler];
}

+ (NSString *)xmlDumpWithData:(NSData *)data
{
    return [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
}

+ (NSString *)textValueFromTextNode:(NSDictionary *)textNode
{
    NSString *value = [textNode objectForKey:@"text"];
    if (value) {
        NSCharacterSet *charsToRemove = [NSCharacterSet whitespaceAndNewlineCharacterSet];
        value = [[value componentsSeparatedByCharactersInSet:charsToRemove] componentsJoinedByString:@""];
    }
    return value;
}

#pragma mark - NSXMLParserDelegate

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    // Get the dictionary for the current level in the stack
    NSMutableDictionary *parentDict = [self.dictionaryStack lastObject];

    // Create the child dictionary for the new element, and initilaize it with the attributes
    NSMutableDictionary *childDict = [NSMutableDictionary dictionary];
    [childDict addEntriesFromDictionary:attributeDict];
    
    // If there's already an item for this key, it means we need to create an array
    id existingValue = [parentDict objectForKey:elementName];
    if (existingValue) {
        NSMutableArray *array = nil;
        if ([existingValue isKindOfClass:[NSMutableArray class]]) {
            array = (NSMutableArray *) existingValue;
        } else {
            array = [NSMutableArray array];
            [array addObject:existingValue];
            [parentDict setObject:array forKey:elementName];
        }
        [array addObject:childDict];
    } else {
        [parentDict setObject:childDict forKey:elementName];
    }
    [self.dictionaryStack addObject:childDict];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    NSMutableDictionary *dictInProgress = [self.dictionaryStack lastObject];
    
    // Set the text property
    if ([self.textInProgress length] > 0) {
        [dictInProgress setObject:self.textInProgress forKey:kXMLReaderTextNodeKey];
        self.textInProgress = nil;
        self.textInProgress = [[[NSMutableString alloc] init] autorelease];
    }
    [self.dictionaryStack removeLastObject];
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    [self.textInProgress appendString:string];
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
    self.error = parseError;
}

@end
