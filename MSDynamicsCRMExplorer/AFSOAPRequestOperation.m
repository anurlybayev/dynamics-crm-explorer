//
//  AFSOAPRequestOperation.m
//  MSDynamicsCRMExplorer
//
//  Created by Akbar Nurlybayev on 2013-03-12.
//  Copyright (c) 2013 Akbar Nurlybayev. All rights reserved.
//

#import "AFSOAPRequestOperation.h"

@implementation AFSOAPRequestOperation

+ (NSSet *)acceptableContentTypes {
    return [NSSet setWithObjects:@"application/xml", @"text/xml", @"application/soap+xml", nil];
}


@end
