//
//  ViewController.m
//  ios-oidc-objc-tester
//
//  Created by Dominik Thalmann on 20.02.20.
//  Copyright © 2020 OneLogin. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"
@import OLOidc;

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextView *infoTextView;
@property OLOidc* olOidc;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.olOidc = [[OLOidc alloc] initWithConfiguration:nil useSecureStorage:true error:nil];
    [AppDelegate sharedInstance].olOidc = self.olOidc;
}

- (void) setInfoText:(NSString*)text {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.infoTextView setText:text];
    });
}

- (IBAction)btnSignInClicked:(id)sender {
    [self.olOidc signInPresenter:self callback:^(NSError * error) {
        if (error != nil) {
            [self setInfoText:[@"Error: " stringByAppendingString:error.localizedDescription]];
            return;
        }
        [self setInfoText:[@"Received access token: " stringByAppendingString:self.olOidc.olAuthState.accessToken]];
    }];
}

- (IBAction)btnIntrospectClicked:(id)sender {
    [self.olOidc introspectWithCallback:^(BOOL tokenValid, NSError * error) {
        if (error != nil) {
            [self setInfoText:[@"Error: " stringByAppendingString:error.localizedDescription]];
            return;
        }
        NSString* status = tokenValid ? @"The token is valid" : @"The token is not valid";
        [self setInfoText:status];
    }];
}

- (IBAction)btnGetUserInfoClicked:(id)sender {
    [self.olOidc getUserInfoWithCallback:^(NSDictionary * userInfo, NSError * error) {
        if (error != nil) {
            [self setInfoText:[@"Error: " stringByAppendingString:error.localizedDescription]];
            return;
        }
        [self setInfoText:[NSString stringWithFormat:@"%@", userInfo]];
    }];
}

- (IBAction)btnDeleteTokensClicked:(id)sender {
    [self.olOidc deleteTokens];
    [self setInfoText:@"Successfully removed local tokens from the keychain"];
}

- (IBAction)btnRevokeAccessTokenClicked:(id)sender {
    [self.olOidc revokeTokenWithTokenType:TokenTypeAccessToken callback:^(NSError * error) {
        if (error != nil) {
            [self setInfoText:[@"Error: " stringByAppendingString:error.localizedDescription]];
            return;
        }
        [self setInfoText:@"Successfully revoked Access-Token"];
    }];
}

- (IBAction)btnRevokeRefreshTokenClicked:(id)sender {
    [self.olOidc revokeTokenWithTokenType:TokenTypeRefreshToken callback:^(NSError * error) {
        if (error != nil) {
            [self setInfoText:[@"Error: " stringByAppendingString:error.localizedDescription]];
            return;
        }
        [self setInfoText:@"Successfully revoked Refresh-Token"];
    }];
}

@end
