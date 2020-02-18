//
//  EndpointType.swift
//  OLOidc
//
//  Created by Dominik Thalmann on 18.02.20.
//  Copyright © 2020 OneLogin. All rights reserved.
//

import Foundation

protocol EndpointConfig {
    var baseURL: URL {get}
    var path: String {get}
    var httpMethod: HTTPMethod {get}
    var body: Data? {get}
    var headers: HTTPHeaders? {get}
}


public enum HTTPMethod : String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
}

public typealias HTTPHeaders = [String:String]

enum NetworkResponse:String {
    case success
    case authenticationError = "Authentication failed."
    case requestInvalid = "The request was invalid"
    case failed = "The request failed."
    case noData = "Response was empty"
}
