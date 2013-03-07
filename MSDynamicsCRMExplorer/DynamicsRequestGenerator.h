//
//  DynamicsRequestGenerator.h
//  MSDynamicsCRMExplorer
//
//  Created by Akbar Nurlybayev on 2013-03-07.
//  Copyright (c) 2013 Akbar Nurlybayev. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DynamicsRequestGenerator : NSObject

- (NSString *)SOAPEnvelopeWithSOAPHeader:(NSString *)header SOAPBody:(NSString *)body;

- (NSString *)SOAPHeaderWithCRMUrl:(NSString *)crmURL
                     keyIdentifier:(NSString *)keyIdentifier
                    securityToken0:(NSString *)token0
                    securityToken1:(NSString *)token1
                            action:(NSString *)action;

- (NSString *)SOAPBodyWithFetchXMLQuery:(NSString *)query;

#pragma mark - Login related

- (NSString *)ocpLogibSOAPHeaderWithUUID:(NSString *)UUID STSEndpoint:(NSString *)STSEndpoint username:(NSString *)username password:(NSString *)password;

- (NSString *)ocpLoginSOAPBodyWithURNAddress:(NSString *)URNAddress;

#pragma mark - Meta related
- (NSString *)metadataSOAPBodyWithObject:(NSString *)object;

- (NSString *)encodeXMLSafeWithXML:(NSString *)xml;

@end
