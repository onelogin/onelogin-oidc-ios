//
//  OLOidcConfig.swift
//  ios-oidc
//
//  Created by Dominik Thalmann on 30.12.19.
//  Copyright © 2019 OneLogin. All rights reserved.
//

import Foundation

public class OLOidcConfig: NSObject, NSCoding {

    @objc public static let configFile = "OL-Oidc-Config"
    @objc public let clientId: String
    @objc public let issuer: String
    @objc public let redirectUri: URL
    @objc public let logoutRedirectUri: URL?
    
    public func encode(with coder: NSCoder) {
        
    }
    
    public required init?(coder: NSCoder) {
        self.clientId = ""
        self.issuer = ""
        self.redirectUri = URL(string: "")!
        self.logoutRedirectUri = nil
    }
}
