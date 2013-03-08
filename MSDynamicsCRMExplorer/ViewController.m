//
//  ViewController.m
//  MSDynamicsCRMExplorer
//
//  Created by Akbar Nurlybayev on 2013-03-07.
//  Copyright (c) 2013 Akbar Nurlybayev. All rights reserved.
//

#import "ViewController.h"
#import "AFNetworking.h"
#import "XMLReader.h"
#import "DynamicsRequestGenerator.h"

NSUInteger const kXML = 0;
NSUInteger const kJSON = 1;

@interface ViewController ()

@property(nonatomic, assign) BOOL isAuthenticated;
@property(nonatomic, copy)   NSString *token0;
@property(nonatomic, copy)   NSString *token1;
@property(nonatomic, copy)   NSString *keyIdentifier;
@property(nonatomic, copy)   NSString *organizationName;
@property(nonatomic, readonly) NSURL *portalURL;
@property(nonatomic, copy)   NSString *xmlResponse;
@property(nonatomic, copy)   NSString *jsonResponse;
@property(nonatomic, strong) AFXMLRequestOperation *currentOperation;

@property(nonatomic, weak) IBOutlet UITextView *queryView;
@property(nonatomic, weak) IBOutlet UITextView *responseView;
@property(nonatomic, weak) IBOutlet UISegmentedControl *xmlJsonSegment;

- (IBAction)sendQuery:(id)sender;
- (IBAction)changeResponse:(UISegmentedControl *)sender;
- (IBAction)clear:(id)sender;

- (BOOL)canAuthorize;

- (void)authorizeSOAPEnvelopeWithAction:(NSString *)apiAction
                              queryBody:(NSString *)soapQueryBody
                      completionHandler:(void (^)(NSString *soapEnvelope, NSError *error))completionBlock;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (!self.isAuthenticated) {
        LoginViewController *lvc = [[LoginViewController alloc] init];
        lvc.delegate = self;
        [self presentViewController:lvc animated:YES completion:NULL];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - LoginViewControllerDelegate
- (void)loginViewController:(LoginViewController *)vc didFinishAuthenticationWithToken0:(NSString *)token0 token1:(NSString *)token1 keyIdentifier:(NSString *)keyIdentifier organizationName:(NSString *)organization
{
    self.token0 = token0;
    self.token1 = token1;
    self.keyIdentifier = keyIdentifier;
    self.organizationName = organization;
    self.isAuthenticated = YES;
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)loginViewController:(LoginViewController *)vc didFailAuthenticationWithError:(NSError *)error
{
    if (error) {
        [[[UIAlertView alloc] initWithTitle:@"Login Failed"
                                    message:[error localizedDescription]
                                   delegate:nil cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
    }
}

- (IBAction)sendQuery:(id)sender
{
    if ([self.queryView.text length]) {
        DynamicsRequestGenerator *generator = [[DynamicsRequestGenerator alloc] init];
        NSString *queryString = [generator encodeXMLSafeWithXML:self.queryView.text];
        NSString *body = [generator SOAPBodyWithFetchXMLQuery:queryString];
        [self authorizeSOAPEnvelopeWithAction:@"RetrieveMultiple"
                                    queryBody:body
                            completionHandler:^(NSString *soapEnvelope, NSError *error) {
                                NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.portalURL];
                                [request setHTTPMethod:@"POST"];
                                [request setValue:@"application/soap+xml" forHTTPHeaderField:@"Content-Type"];
                                [request setValue:@"application/soap+xml" forHTTPHeaderField:@"Accept"];
                                request.HTTPBody = [soapEnvelope dataUsingEncoding:NSUTF8StringEncoding];
                                self.currentOperation =
                                [AFXMLRequestOperation XMLParserRequestOperationWithRequest:request
                                                                                    success:
                                 ^(NSURLRequest *request, NSHTTPURLResponse *response, NSXMLParser *XMLParser) {
                                     [XMLReader parseXMLWithNSXMLParser:XMLParser
                                                      completionHandler:
                                      ^(id json, NSError *error) {
                                          if (error) {
                                              [[[UIAlertView alloc] initWithTitle:@"Parsing Failed"
                                                                          message:[error localizedDescription]
                                                                         delegate:nil
                                                                cancelButtonTitle:@"OK"
                                                                otherButtonTitles:nil] show];
                                          } else {
                                              self.xmlResponse = self.currentOperation.responseString;
                                              self.jsonResponse = [json description];
                                              if (self.xmlJsonSegment.selectedSegmentIndex == kXML) {
                                                  self.responseView.text = self.xmlResponse;
                                              } else {
                                                  self.responseView.text = self.jsonResponse;
                                              }
                                              self.currentOperation = nil;
                                          }
                                      }];
                                 }
                                                                                    failure:
                                 ^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, NSXMLParser *XMLParser) {
                                     [[[UIAlertView alloc] initWithTitle:@"Query Failed"
                                                                 message:[error localizedDescription]
                                                                delegate:nil
                                                       cancelButtonTitle:@"OK"
                                                       otherButtonTitles:nil] show];
                                     self.currentOperation = nil;
                                 }];
                            }];
        [self.currentOperation start];
    }
}

- (IBAction)changeResponse:(UISegmentedControl *)sender
{
    if (sender.selectedSegmentIndex == kXML) {
        self.responseView.text = self.xmlResponse;
    } else {
        self.responseView.text = self.jsonResponse;
    }
}

- (IBAction)clear:(id)sender
{
    self.responseView.text = @"";
}

- (NSURL *)portalURL
{
    return [NSURL URLWithString:[NSString stringWithFormat:kPortalURL, self.organizationName]];
}

- (BOOL)canAuthorize
{
    return (self.token0 && self.token1 && self.keyIdentifier) ? YES : NO;
}

- (void)authorizeSOAPEnvelopeWithAction:(NSString *)apiAction queryBody:(NSString *)soapQueryBody completionHandler:(void (^)(NSString *, NSError *))completionBlock
{
    if ([self canAuthorize]) {
        DynamicsRequestGenerator *generator = [[DynamicsRequestGenerator alloc] init];
        NSString *header = [generator SOAPHeaderWithCRMUrl:[NSString stringWithFormat:kPortalURL, self.organizationName]
                                             keyIdentifier:self.keyIdentifier
                                            securityToken0:self.token0
                                            securityToken1:self.token1
                                                    action:apiAction];
        NSString *envelope = [generator SOAPEnvelopeWithSOAPHeader:header SOAPBody:soapQueryBody];
        completionBlock(envelope, nil);
    } else {
        completionBlock(nil, [NSError errorWithDomain:@"RootViewControllerDomain"
                                                 code:401
                                             userInfo:@{NSLocalizedDescriptionKey: @"No Active Session"}]);
    }
}

@end
