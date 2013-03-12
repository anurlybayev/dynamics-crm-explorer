//
//  LoginViewController.m
//  MSDynamicsCRMExplorer
//
//  Created by Akbar Nurlybayev on 2013-03-07.
//  Copyright (c) 2013 Akbar Nurlybayev. All rights reserved.
//

#import "LoginViewController.h"
#import "AFNetworking.h"
#import "AFSOAPRequestOperation.h"
#import "XMLReader.h"
#import "DynamicsRequestGenerator.h"

NSString *const kPortalURL = @"https://%@.crm.dynamics.com/XRMServices/2011/Organization.svc";
NSString *const kURNAddress = @"URNAddress";
NSString *const kSTSEndpoint = @"STSEnpoint";
NSString *const kUserDefaultsKeyOrganizationName = @"Dynamics CRM Organization Name";
NSString *const kUserDefaultsKeyUsername = @"Dynamics CRM Username";
NSString *const kUserDefaultsKeyPassword = @"Dynamics CRM Password";

@interface LoginViewController ()

@property(nonatomic, weak) IBOutlet UITextField *organizationName;
@property(nonatomic, weak) IBOutlet UITextField *username;
@property(nonatomic, weak) IBOutlet UITextField *password;
@property(nonatomic, weak) IBOutlet UISwitch *remember;

- (IBAction)login:(id)sender;

@end

@implementation LoginViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:kUserDefaultsKeyOrganizationName]) {
        self.organizationName.text = [defaults objectForKey:kUserDefaultsKeyOrganizationName];
        self.username.text = [defaults objectForKey:kUserDefaultsKeyUsername];
        self.password.text = [defaults objectForKey:kUserDefaultsKeyPassword];
        self.remember.on = YES;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)login:(id)sender
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (self.remember.on) {
        [defaults setObject:self.organizationName.text forKey:kUserDefaultsKeyOrganizationName];
        [defaults setObject:self.username.text forKey:kUserDefaultsKeyUsername];
        [defaults setObject:self.password.text forKey:kUserDefaultsKeyPassword];
    } else {
        [defaults removeObjectForKey:kUserDefaultsKeyOrganizationName];
        [defaults removeObjectForKey:kUserDefaultsKeyUsername];
        [defaults removeObjectForKey:kUserDefaultsKeyPassword];
    }
    [defaults synchronize];
    NSString *wsdlURL = [NSString stringWithFormat:@"%@?wsdl", kPortalURL];
    wsdlURL = [NSString stringWithFormat:wsdlURL, self.organizationName.text];
    
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:wsdlURL]];
    AFSOAPRequestOperation *operation =
    [AFSOAPRequestOperation XMLParserRequestOperationWithRequest:request
                                                        success:
     ^(NSURLRequest *request, NSHTTPURLResponse *response, NSXMLParser *XMLParser) {
         [XMLReader parseXMLWithNSXMLParser:XMLParser completionHandler:^(id json, NSError *error) {
             if (error) {
                 [self.delegate loginViewController:self didFailAuthenticationWithError:error];
             } else {
                 NSString *location = [json valueForKeyPath:@"definitions.import.location"];
                 [self fetchWSDLImport:location];
             }
         }];
     }
                                                        failure:
     ^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, NSXMLParser *XMLParser) {
         [self.delegate loginViewController:self didFailAuthenticationWithError:error];
     }];
    [operation start];
}

- (void)fetchWSDLImport:(NSString *)wsdlImportURL
{
    NSURL *url = [NSURL URLWithString:wsdlImportURL];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
    
    AFSOAPRequestOperation *operation =
    [AFSOAPRequestOperation XMLParserRequestOperationWithRequest:request
                                                        success:
     ^(NSURLRequest *request, NSHTTPURLResponse *response, NSXMLParser *XMLParser) {
         [XMLReader parseXMLWithNSXMLParser:XMLParser completionHandler:^(id json, NSError *error) {
             if (error) {
                 [self.delegate loginViewController:self didFailAuthenticationWithError:error];
             } else {
                 NSString *URNAddress = nil;
                 NSString *STSEndpoint = nil;
                 NSArray *authenticationPolicy = [json valueForKeyPath:@"definitions.Policy.ExactlyOne.All.AuthenticationPolicy"];
                 for (NSDictionary *policy in authenticationPolicy) {
                     NSString *authentication = [XMLReader textValueFromTextNode:[policy objectForKey:@"Authentication"]];
                     if ([authentication isEqualToString:@"LiveId"]) {
                         NSString *appliesTo = [XMLReader textValueFromTextNode:[policy valueForKeyPath:@"SecureTokenService.LiveTrust.AppliesTo"]];
                         URNAddress = appliesTo;
                         break;
                     }
                 }
                 STSEndpoint = [XMLReader textValueFromTextNode:[json valueForKeyPath:@"definitions.Policy.ExactlyOne.All.SignedSupportingTokens.Policy.IssuedToken.Issuer.Address"]];
                 if ([STSEndpoint hasPrefix:@"https://login.live.com"]) {
                     NSError *authError = [NSError errorWithDomain:@"LoginViewControllerDomain"
                                                              code:401
                                                          userInfo:@{NSLocalizedDescriptionKey: @"This authentication is not implemented"}];
                     [self.delegate loginViewController:self didFailAuthenticationWithError:authError];
                 } else {
                     [self fetchSecurityTokensWithURNAddress:URNAddress
                                                 STSEndpoint:STSEndpoint
                                                    username:self.username.text
                                                    password:self.password.text];
                 }
             }
         }];
     }
                                                        failure:
     ^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, NSXMLParser *XMLParser) {
         [self.delegate loginViewController:self didFailAuthenticationWithError:error];
     }];
    [operation start];
}

- (void)fetchSecurityTokensWithURNAddress:(NSString *)URNAddress STSEndpoint:(NSString *)STSEndpoint username:(NSString *)username password:(NSString *)password
{
    // Step A: Get Security Token by sending OCP username, password
    DynamicsRequestGenerator *generator = [[DynamicsRequestGenerator alloc] init];
    NSString *header = [generator ocpLogibSOAPHeaderWithUUID:[[NSUUID UUID] UUIDString]
                                                 STSEndpoint:STSEndpoint
                                                    username:username
                                                    password:password];
    NSString *body = [generator ocpLoginSOAPBodyWithURNAddress:URNAddress];
    NSString *envelope = [generator SOAPEnvelopeWithSOAPHeader:header SOAPBody:body];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:STSEndpoint]];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/soap+xml" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/xml" forHTTPHeaderField:@"Accept"];
    request.HTTPBody = [envelope dataUsingEncoding:NSUTF8StringEncoding];
    AFSOAPRequestOperation *operation =
    [AFSOAPRequestOperation XMLParserRequestOperationWithRequest:request
                                                        success:
     ^(NSURLRequest *request, NSHTTPURLResponse *response, NSXMLParser *XMLParser) {
         [XMLReader parseXMLWithNSXMLParser:XMLParser completionHandler:^(id json, NSError *error) {
             if (error) {
                 [self.delegate loginViewController:self didFailAuthenticationWithError:error];
             } else {
                 if ([json valueForKeyPath:@"Envelope.Body.Fault"]) {
                     NSDictionary *reason = [json valueForKeyPath:@"Envelope.Body.Fault.Reason.Text"];
                     NSError *authError = [NSError errorWithDomain:@"LoginViewControllerDomain"
                                                              code:401
                                                          userInfo:@{NSLocalizedDescriptionKey: [reason objectForKey:@"text"]}];
                     [self.delegate loginViewController:self
                         didFailAuthenticationWithError:authError];
                     
                 } else {
                     NSDictionary *encryptedData = [json valueForKeyPath:@"Envelope.Body.RequestSecurityTokenResponse.RequestedSecurityToken.EncryptedData"];
                     NSString *token1 = [XMLReader textValueFromTextNode:[encryptedData valueForKeyPath:@"CipherData.CipherValue"]];
                     NSDictionary *encryptedKey = [encryptedData valueForKeyPath:@"KeyInfo.EncryptedKey"];
                     NSString *token0 = [XMLReader textValueFromTextNode:[encryptedKey valueForKeyPath:@"CipherData.CipherValue"]];
                     NSDictionary *keyIdentifier = [encryptedKey valueForKeyPath:@"KeyInfo.SecurityTokenReference.KeyIdentifier"];
                     NSString *key = [keyIdentifier objectForKey:@"text"];
                     [self.delegate loginViewController:self didFinishAuthenticationWithToken0:token0 token1:token1 keyIdentifier:key organizationName:self.organizationName.text];
                 }
             }
         }];
     }
                                                        failure:
     ^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, NSXMLParser *XMLParser) {
         [self.delegate loginViewController:self didFailAuthenticationWithError:error];
     }];
    [operation start];
}

@end
