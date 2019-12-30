//
//  OLOidcAuthState.swift
//  ios-oidc
//
//  Created by Dominik Thalmann on 30.12.19.
//  Copyright © 2019 OneLogin. All rights reserved.
//

import Foundation

open class OLOidcAuthState: NSObject, NSCoding {
    
    @objc open var authState: OIDAuthState?
    @objc open var accessToken: String?
    @objc open var idToken: String?
    @objc open var refreshToken: String?
    
    public func encode(with coder: NSCoder) {
        
    }
    
    public required init?(coder: NSCoder) {
        
    }
}
