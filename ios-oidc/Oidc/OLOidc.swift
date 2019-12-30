//
//  OLOidc.swift
//  ios-oidc
//
//  Created by Dominik Thalmann on 30.12.19.
//  Copyright © 2019 OneLogin. All rights reserved.
//

import Foundation

public class OLOidc: NSObject {
    
    @objc public let configuration: OLOidcConfig?
    
    @objc public init(configuration: OLOidcConfig? = nil) throws {
        if let config = configuration {
            self.configuration = config
        } else {
            // try to load a default
            self.configuration = nil
        }
    }
    
    @objc public func signIn() {
        
    }

    @objc public func signOut() {

    }

    @objc public func authenticate() {

    }
}
