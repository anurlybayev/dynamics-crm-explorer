//
//  DynamicsRequestGenerator.m
//  MSDynamicsCRMExplorer
//
//  Created by Akbar Nurlybayev on 2013-03-07.
//  Copyright (c) 2013 Akbar Nurlybayev. All rights reserved.
//
#import "DynamicsRequestGenerator.h"

NSTimeInterval const kExpiryDuration = 300;

@implementation DynamicsRequestGenerator

- (NSString *)SOAPEnvelopeWithSOAPHeader:(NSString *)header SOAPBody:(NSString *)body
{
    NSString *soapEnvelope = [@[
                              @"<?xml version='1.0' ?>",
                              @"<s:Envelope xmlns:s='http://www.w3.org/2003/05/soap-envelope' ",
                              @"xmlns:a='http://www.w3.org/2005/08/addressing' ",
                              @"xmlns:u='http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd'>", header, body, @"</s:Envelope>"
                              ] componentsJoinedByString:@""];
    return soapEnvelope;
}

- (NSString *)SOAPHeaderWithCRMUrl:(NSString *)crmURL
                     keyIdentifier:(NSString *)keyIdentifier
                    securityToken0:(NSString *)token0
                    securityToken1:(NSString *)token1
                            action:(NSString *)action
{
    NSDate *dateCreated = [NSDate date];
    NSDate *dateExpired = [dateCreated dateByAddingTimeInterval:kExpiryDuration];
    NSString *timeCreated = [[DynamicsRequestGenerator dateFormatter] stringFromDate:dateCreated];
    NSString *timeExpires = [[DynamicsRequestGenerator dateFormatter] stringFromDate:dateExpired];
    NSString *soapHeader = [@[
                            @"<s:Header>",
                            @"<a:Action s:mustUnderstand='1'>",
                            @"http://schemas.microsoft.com/xrm/2011/Contracts/Services/IOrganizationService/",
                            action,
                            @"</a:Action>",
                            @"<a:MessageID>",
                            @"urn:uuid:", [[NSUUID UUID] UUIDString],
                            @"</a:MessageID>",
                            @"<a:ReplyTo><a:Address>http://www.w3.org/2005/08/addressing/anonymous</a:Address></a:ReplyTo>",
                            @"<VsDebuggerCausalityData xmlns='http://schemas.microsoft.com/vstudio/diagnostics/servicemodelsink'>",
                            @"uIDPozJEz+P/wJdOhoN2XNauvYcAAAAAK0Y6fOjvMEqbgs9ivCmFPaZlxcAnCJ1GiX+Rpi09nSYACQAA"
                            @"</VsDebuggerCausalityData>",
                            @"<a:To s:mustUnderstand='1'>",
                            crmURL,
                            @"</a:To>",
                            @"<o:Security s:mustUnderstand='1' xmlns:o='http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd'>",
                            @"<u:Timestamp u:Id='_0'>",
                            @"<u:Created>", timeCreated, @"</u:Created>",
                            @"<u:Expires>", timeExpires, @"</u:Expires>",
                            @"</u:Timestamp>",
                            @"<EncryptedData Id='Assertion0' Type='http://www.w3.org/2001/04/xmlenc#Element' xmlns='http://www.w3.org/2001/04/xmlenc#'>",
                            @"<EncryptionMethod Algorithm='http://www.w3.org/2001/04/xmlenc#tripledes-cbc'></EncryptionMethod>",
                            @"<ds:KeyInfo xmlns:ds='http://www.w3.org/2000/09/xmldsig#'>",
                            @"<EncryptedKey>",
                            @"<EncryptionMethod Algorithm='http://www.w3.org/2001/04/xmlenc#rsa-oaep-mgf1p'></EncryptionMethod>",
                            @"<ds:KeyInfo Id='keyinfo'>",
                            @"<wsse:SecurityTokenReference xmlns:wsse='http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd'>",
                            @"<wsse:KeyIdentifier EncodingType='http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary' ValueType='http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-x509-token-profile-1.0#X509SubjectKeyIdentifier'>",
                            keyIdentifier,
                            @"</wsse:KeyIdentifier>",
                            @"</wsse:SecurityTokenReference>",
                            @"</ds:KeyInfo>",
                            @"<CipherData><CipherValue>",
                            token0,
                            @"</CipherValue></CipherData>",
                            @"</EncryptedKey>",
                            @"</ds:KeyInfo>",
                            @"<CipherData><CipherValue>",
                            token1,
                            @"</CipherValue></CipherData>",
                            @"</EncryptedData>",
                            @"</o:Security>",
                            @"</s:Header>"] componentsJoinedByString:@""];
    return soapHeader;
}

- (NSString *)SOAPBodyWithFetchXMLQuery:(NSString *)query
{
    NSString *soapBody = [@[
                          @"<s:Body>",
                          @"<RetrieveMultiple xmlns='http://schemas.microsoft.com/xrm/2011/Contracts/Services'>",
                          @"<query i:type='b:FetchExpression' xmlns:b='http://schemas.microsoft.com/xrm/2011/Contracts' xmlns:i='http://www.w3.org/2001/XMLSchema-instance'>",
                          @"<b:Query>",
                          query,
                          @"</b:Query>",
                          @"</query>",
                          @"</RetrieveMultiple>",
                          @"</s:Body>",
                          ] componentsJoinedByString:@""];
    return soapBody;
}

#pragma mark - Login related

- (NSString *)ocpLogibSOAPHeaderWithUUID:(NSString *)UUID STSEndpoint:(NSString *)STSEndpoint username:(NSString *)username password:(NSString *)password
{
    NSDate *dateCreated = [NSDate date];
    NSDate *dateExpired = [dateCreated dateByAddingTimeInterval:kExpiryDuration];
    NSString *timeCreated = [[DynamicsRequestGenerator dateFormatter] stringFromDate:dateCreated];
    NSString *timeExpires = [[DynamicsRequestGenerator dateFormatter] stringFromDate:dateExpired];
    return [@[
            @"<s:Header>",
            @"<a:Action s:mustUnderstand='1'>http://schemas.xmlsoap.org/ws/2005/02/trust/RST/Issue</a:Action>",
            @"<a:MessageID>urn:uuid:", UUID ,@"</a:MessageID>",
            @"<a:ReplyTo><a:Address>http://www.w3.org/2005/08/addressing/anonymous</a:Address></a:ReplyTo>",
            @"<VsDebuggerCausalityData xmlns='http://schemas.microsoft.com/vstudio/diagnostics/servicemodelsink'>uIDPo4TBVw9fIMZFmc7ZFxBXIcYAAAAAbd1LF/fnfUOzaja8sGev0GKsBdINtR5Jt13WPsZ9dPgACQAA</VsDebuggerCausalityData>",
            @"<a:To s:mustUnderstand='1'>", STSEndpoint, @"</a:To>",
            @"<o:Security s:mustUnderstand='1' xmlns:o='http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd'>",
            @"<u:Timestamp u:Id='_0'>",
            @"<u:Created>", timeCreated, @"</u:Created>",
            @"<u:Expires>", timeExpires, @"</u:Expires>",
            @"</u:Timestamp>",
            @"<o:UsernameToken u:Id='uuid-14bed392-2320-44ae-859d-fa4ec83df57a-1'>",
            @"<o:Username>", username, @"</o:Username>",
            @"<o:Password Type='http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText'>", password, @"</o:Password>",
            @"</o:UsernameToken>",
            @"</o:Security>",
            @"</s:Header>"] componentsJoinedByString:@""];
}

- (NSString *)ocpLoginSOAPBodyWithURNAddress:(NSString *)URNAddress
{
    return [@[
            @"<s:Body>",
            @"<t:RequestSecurityToken xmlns:t='http://schemas.xmlsoap.org/ws/2005/02/trust'>",
            @"<wsp:AppliesTo xmlns:wsp='http://schemas.xmlsoap.org/ws/2004/09/policy'>",
            @"<a:EndpointReference>",@"<a:Address>",URNAddress,@"</a:Address>",@"</a:EndpointReference>",
            @"</wsp:AppliesTo>",
            @"<t:RequestType>http://schemas.xmlsoap.org/ws/2005/02/trust/Issue</t:RequestType>",
            @"</t:RequestSecurityToken>",
            @"</s:Body>"] componentsJoinedByString:@""];
}

#pragma mark - Meta related

- (NSString *)metadataSOAPBodyWithObject:(NSString *)object
{
    return [@[
            @"<s:Body>",
            @"<Execute xmlns='http://schemas.microsoft.com/xrm/2011/Contracts/Services' xmlns:i='http://www.w3.org/2001/XMLSchema-instance'>",
            @"<request i:type='a:RetrieveEntityRequest' xmlns:a='http://schemas.microsoft.com/xrm/2011/Contracts'>",
            @"<a:Parameters xmlns:b='http://schemas.datacontract.org/2004/07/System.Collections.Generic'>",
            @"<a:KeyValuePairOfstringanyType>",
            @"<b:key>EntityFilters</b:key>",
            @"<b:value i:type='c:EntityFilters' xmlns:c='http://schemas.microsoft.com/xrm/2011/Metadata'>Entity Attributes Relationships</b:value>",
            @"</a:KeyValuePairOfstringanyType>",
            @"<a:KeyValuePairOfstringanyType>",
            @"<b:key>MetadataId</b:key>",
            @"<b:value i:type='c:guid' xmlns:c='http://schemas.microsoft.com/2003/10/Serialization/'>00000000-0000-0000-0000-000000000000</b:value>",
            @"</a:KeyValuePairOfstringanyType>",
            @"<a:KeyValuePairOfstringanyType>",
            @"<b:key>RetrieveAsIfPublished</b:key>",
            @"<b:value i:type='c:boolean' xmlns:c='http://www.w3.org/2001/XMLSchema'>false</b:value>",
            @"</a:KeyValuePairOfstringanyType>",
            @"<a:KeyValuePairOfstringanyType>",
            @"<b:key>LogicalName</b:key>",
            @"<b:value i:type='c:string' xmlns:c='http://www.w3.org/2001/XMLSchema'>",
            object,
            @"</b:value>",
            @"</a:KeyValuePairOfstringanyType>",
            @"</a:Parameters>",
            @"<a:RequestId i:nil='true' />",
            @"<a:RequestName>RetrieveEntity</a:RequestName>",
            @"</request>",
            @"</Execute>",
            @"</s:Body>",
            ] componentsJoinedByString:@""];
}

#pragma mark -

+ (NSDateFormatter *)dateFormatter
{
    static NSString *const kDateFormatterKey = @"SOAP Header date formatter key";
    NSMutableDictionary *dictionary = [[NSThread currentThread] threadDictionary];
    NSDateFormatter *df = [dictionary objectForKey:kDateFormatterKey];
    if (!df)
    {
        df = [[NSDateFormatter alloc] init];
        df.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        df.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'.'SSSS'Z'";
        df.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
        [dictionary setObject:df forKey:kDateFormatterKey];
    }
    return df;
}

- (NSString *)encodeXMLSafeWithXML:(NSString *)xml
{
    NSString* newString = [xml stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"];
    newString = [newString stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"];
    newString = [newString stringByReplacingOccurrencesOfString:@">" withString:@"&gt;"];
    newString = [newString stringByReplacingOccurrencesOfString:@"\"" withString:@"&quot;"];
    newString = [newString stringByReplacingOccurrencesOfString:@"'" withString:@"&#x27;"];
    return newString;
}

@end
