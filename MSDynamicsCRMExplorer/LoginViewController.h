//
//  LoginViewController.h
//  MSDynamicsCRMExplorer
//
//  Created by Akbar Nurlybayev on 2013-03-07.
//  Copyright (c) 2013 Akbar Nurlybayev. All rights reserved.
//

#import <UIKit/UIKit.h>

FOUNDATION_EXPORT NSString *const kPortalURL;

@class LoginViewController;
@protocol LoginViewControllerDelegate <NSObject>
@required
- (void)loginViewController:(LoginViewController *)vc didFinishAuthenticationWithToken0:(NSString *)token0 token1:(NSString *)token1 keyIdentifier:(NSString *)keyIdentifier organizationName:(NSString *)organization;
- (void)loginViewController:(LoginViewController *)vc didFailAuthenticationWithError:(NSError *)error;


@end

@interface LoginViewController : UIViewController

@property(nonatomic, weak) id<LoginViewControllerDelegate> delegate;

@end
