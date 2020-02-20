//
//  Endpoints.swift
//  OLOidc
//
//  Created by Dominik Thalmann on 18.02.20.
//  Copyright © 2020 OneLogin. All rights reserved.
//

import Foundation

public enum Endpoint {
    case revoke(tokenEndpoint: URL, accessToken: String, clientId: String)
    case introspect(tokenEndpoint: URL, accessToken: String, clientId: String)
}

extension Endpoint: EndpointConfig {
    
    var baseURL: URL {
        switch self {
        case .revoke(let tokenEndpoint, _, _):
            return tokenEndpoint
        case .introspect(let tokenEndpoint, _, _):
            return tokenEndpoint
        }
    }
    
    var path: String {
        switch self {
        case .revoke:
            return "revocation"
        case .introspect:
            return "introspection"
        }
    }
    
    var httpMethod: HTTPMethod {
        switch self {
        case .revoke:
            return .post
        case .introspect:
            return .post
        }
    }
    
    var headers: HTTPHeaders? {
        switch self {
        case .revoke:
            return ["Content-Type": "application/x-www-form-urlencoded"]
        case .introspect:
            return ["Content-Type": "application/x-www-form-urlencoded"]
        }
    }
    
    var body: Data? {
        switch self {
        case .revoke(_, let accessToken, let clientId):
            let body: [String: String] = ["token": accessToken,
                                       "token_type_hint": "access_token",
                                       "client_id": clientId]
            let bodyData = self.encodeParameters(parameters: body)
            return bodyData
        case .introspect(_, let accessToken, let clientId):
            let body: [String: String] = ["token": accessToken,
                                       "token_type_hint": "access_token",
                                       "client_id": clientId]
            let bodyData = self.encodeParameters(parameters: body)
            return bodyData
        }
    }
    
    
    func toBase64(text: String) -> String? {
        guard let data = text.data(using: String.Encoding.utf8) else {
            return nil
        }
        return data.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
    }
    
    func encodeParameters(parameters: [String : String]) -> Data{
        let parameterArray = parameters.map { (key, value) -> String in
            return "\(key)=\(value)"
        }
        
        let resultString = parameterArray.joined(separator: "&")
        return resultString.data(using: .utf8)!
    }
}
