//
//  OLOidcError.swift
//  ios-oidc
//
//  Created by Dominik Thalmann on 04.02.20.
//  Copyright © 2020 OneLogin. All rights reserved.
//

public enum OLOidcError: Error, Equatable {
    // Configuration
    case configFileNotFound
    case configFileParseFailure
    case configInvalid
    case missingConfiguration
    case tokenEndpointUndeclared
    case userEndpointUndeclared
    case fetchingFreshTokenError(String)
    case gettingAccessTokenError
    case gettingIdTokenError
    case httpRequestFailed(String)
    case nonHttpResponse
    case noResponseData
    case jsonSerializationError
    case authorizationError(String)
    case unknownError
}

extension OLOidcError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .configFileNotFound:
            return "The config file could not be found."
        case .configFileParseFailure:
            return "The config file could not be parsed correctly."
        case .missingConfiguration:
            return "No configuration was provided to OLOidc."
        case .configInvalid:
            return "The config file contains invalid parameters."
        case .tokenEndpointUndeclared:
            return "Token endpoint not declared in discovery document."
        case .userEndpointUndeclared:
            return "Userinfo endpoint not declared in discovery document."
        case .fetchingFreshTokenError(error: let error):
            return "Error fetching fresh tokens: \(error)"
        case .gettingAccessTokenError:
            return "Error getting accessToken"
        case .gettingIdTokenError:
            return "Error getting idToken"
        case .httpRequestFailed(error: let error):
            return "HTTP request failed \(error)"
        case .nonHttpResponse:
            return "Non-HTTP response"
        case .noResponseData:
            return "HTTP response data is empty"
        case .jsonSerializationError:
            return "JSON Serialization Error"
        case .authorizationError(error: let error):
            return "Authorization Error: \(error)"
        case .unknownError:
            return "unknown error"
        }
    }
}
