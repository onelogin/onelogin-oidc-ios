# OneLogin Open ID Connect Library

This library is a swift wrapper for the AppAuth code to communicate with OneLogin as an OpenID Connect provider. It supports [Auth Code Flow + PKCE](https://developers.onelogin.com/openid-connect/guides/auth-flow-pkce) which is recommended for native apps.

To get more info about how to configure an app for OIDC visit the [Overview of OpenID Connect](https://developers.onelogin.com/openid-connect) page. 


**Table of Contents**

<!-- TOC depthFrom:2 depthTo:3 -->

- [Installation](#installation)
- [Configuration](#configuration)
  - [Configure an OneLogin application](#configure-an-onelogin-application)
  - [Framework configuration](#framework-configuration)
- [Authorization redirect](#authorization-redirect)
- [Secure Storage](#secure-storage)
- [API overview](#api-overview)
  - [signIn](#signIn)
  - [endLocalSession](#endlocalsession)
  - [signOut](#signout)
  - [introspect](#introspect)
  - [getUserInfo](#getuserinfo)

<!-- /TOC -->


## Installation

To install the OLOidc SDK into your project just download the project and open `ios-oidc.xcodeproj`in XCode. Build the `OLOidc` target to create the framework. After that open your project in XCode and go to the `Build Phases` tab of your target. Under `Link Binaries With Libraries`press the plus button and select the OLOidc framework. Alternatively you can drag and drop the framework to the `Frameworks`group in the project navigator.

## Configuration

Before you can use OLOidc you need to configure an OneLogin application and provide some configuration parameters about your app to the framework.

### Configure an OneLogin application

Please visit the [Connect an OIDC enabled app](https://developers.onelogin.com/openid-connect/connect-to-onelogin) page for instructions on how to configure your OneLogin app.

### Framework configuration

In order for the framework to authorize a user, it needs some parameters about your application. There are two ways to provide these parameters.

The easiest method is to use a property list (`.plist`) file. If you don't specify a plist name the framework checks if a `OL-Oidc.plist`file exists. If your file has a different name you will have to provide the name during initialization.

Using default plist file:
```swift
let olOidc = try? OLOidc(configuration: nil)
```

Using a different plist name:
```swift
let olOidcConfig = OLOidcConfig(plist: "myPlistName")
let olOidc = OLOidc(configuration: olOidcConfig)
])
```

Alternatively you can initialize a configuration object (`OLOidcConfig`) directly by providing the required parameters as a dictionary:

```swift
let olOidcConfig = OLOidcConfig(dict: [
  "issuer": "{yourIssuer}",
  "clientId": "{clientID}",
  "redirectUri": "{redirectUri}",
  "scopes": "openid profile"
])
let olOidc = OLOidc(configuration: olOidcConfig)
```

Required parameters are:
 - issuer
 - clientId
 - redirectUri
 - scopes (requires at least `openid`, values are space separated)

## Authorization redirect

During the authorization, a redirect to your application must take place. For this to work, an url scheme must be registered. To do this, open the Info.plist of your app and add a URL scheme that matches the redirect URI.
For example, the url scheme for the redirect URI `com.onelogin.oidc://callback` would be `com.onelogin.oidc`

In your AppDelegate you have to include the following function:

```swift
// AppDelegate.swift
import OLOidc

var olOidc : OLOidc?

func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
  guard #available(iOS 11, *) else {
            return olOidc?.currentAuthorizationFlow?.resumeExternalUserAgentFlow(with: url) ?? false
        }
  return false
}
```

Please note: If you initialize your `OLOidc`object remember to set the `olOidc` variable in the AppDelegate to that instance.

## Secure Storage

By default all authentication data gets saved automatically in the Keychain. This is the most secure method available on iOS. The access level for the data ist set to be very restrictive. That means the data is only available if the device is unlocked and can never be transfered to another device using iTunes or other restore options.

After a successful authorization the received tokens get written to the keychain and stored under a specific key which is based on the app the user is authorizing to. That means you can store oidc data for multiple apps.
During initialization for a specific configuration previous data will be loaded automatically so that you don't have to care about saving/loading at all.

If you don't want the received data to be saved in the keychain automatically you can do so by setting a flag when initializing an `OLOidc` object:

```swift
let olOidc = OLOidc(configuration: myConfiguration, useSecureStorage: false)
```

You can manually save/load/delete your authentication data:

```swift
let olOidc = try? OLOidc(configuration: nil)

// load data from keychain
let authState = olOidc?.olAuthState.readFromKeychain()

// save data to keychain
olOidc?.olAuthState.writeToKeychain()

// delete data for this configuration
olOidc?.olAuthState.deleteFromKeychain()
```

## API overview

### signIn

To start the authorization you have to initialize an `OLOidc` object and call `signIn`. The function will return an error in the callback if something goes wrong. If the authorization was successful, the response data will be saved securely in the keychain and you can access it easily through the `OLOidcAuthState`object:

```swift
olOidc?.signIn(presenter: self) { error in
    if error == nil {      
        let accessToken = self.olOidc?.olAuthState.accessToken
        let refreshToken = self.olOidc?.olAuthState.refreshToken
        let idToken = self.olOidc?.olAuthState.idToken
    }
}
```

### endLocalSession

To remove a local session you can call `endLocalSession`. This will remove the saved session data from the keychain. Please note that this won't remove any cookies and also does not revoke an access token on the server:

```swift
olOidc?.endLocalSession()
```

### signOut

To revoke an access token on the server you can call `signOut`. If the call is successful your local access token won't work for authorization anymore:

```swift
olOidc?.signOut(callback: { (error) in
    if error != nil {
        // the access token has been revoked 
    }
})
```

### introspect

In order to check the validity of an access token you can call `introspect`:

```swift
olOidc?.introspect(callback: { (tokenValid, error) in

})
```

### getUserInfo

To get user information you can call the `getUserInfo` function:

```swift
olOidc?.getUserInfo(callback: { (userInfo, error) in
            if let error = error {
                // some error occured
                return
            }
            print("\(String(describing: userInfo))")
        })
```