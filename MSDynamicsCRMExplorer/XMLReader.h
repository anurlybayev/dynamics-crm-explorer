//
//  XMLReader.h
//  MSDynamicsCRMExplorer
//
//  Created by Akbar Nurlybayev on 2013-03-07.
//  Copyright (c) 2013 Akbar Nurlybayev. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XMLReader : NSObject <NSXMLParserDelegate>

// This class is basedon http://troybrant.net/blog/2010/09/simple-xml-to-nsdictionary-converter/

+ (void)parseXMLWithNSXMLParser:(NSXMLParser *)parser completionHandler:(void (^)(id, NSError *))handler;
+ (void)parseXMLData:(NSData *)data completionHandler:(void (^)(id, NSError *))handler;
+ (void)parseXMLString:(NSString *)xml completionHandler:(void (^)(id, NSError *))handler;

+ (NSString *)xmlDumpWithData:(NSData *)data;
+ (NSString *)textValueFromTextNode:(NSDictionary *)textNode;
@end
