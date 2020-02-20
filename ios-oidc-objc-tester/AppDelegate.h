//
//  AppDelegate.h
//  ios-oidc-objc-tester
//
//  Created by Dominik Thalmann on 20.02.20.
//  Copyright © 2020 OneLogin. All rights reserved.
//

#import <UIKit/UIKit.h>
@import OLOidc;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (nullable) OLOidc* olOidc;
+ (AppDelegate*_Nonnull) sharedInstance;

@end

