//
//  Router.swift
//  OLOidc
//
//  Created by Dominik Thalmann on 18.02.20.
//  Copyright © 2020 OneLogin. All rights reserved.
//

import Foundation


//
public typealias networkCallback = (_ data: Data?,_ response: URLResponse?,_ error: Error?)->()

public class Router {
    var task: URLSessionDataTask?
    
    func request(endpoint: Endpoint, completion: @escaping networkCallback) {
        let session = URLSession.shared
        do {
            let request = try self.createRequest(endpoint: endpoint)
            task = session.dataTask(with: request, completionHandler: { data, response, error in
                
                guard let response = response as? HTTPURLResponse else {
                    completion(nil, nil, OLOidcError.nonHttpResponse)
                    return
                }

                guard let data = data else {
                    completion(nil, nil, OLOidcError.noResponseData)
                    return
                }

                if response.statusCode != 200 {
                    // server replied with an error
                    let responseText: String? = String(data: data, encoding: String.Encoding.utf8)
                    if response.statusCode == 401 {
                        completion(nil, nil, OLOidcError.authorizationError("(Response: \(responseText ?? "RESPONSE_TEXT")"))
                    } else {
                        completion(nil, nil, OLOidcError.authorizationError("(\(response.statusCode)). Response: \(responseText ?? "RESPONSE_TEXT")"))
                    }

                    return
                }
                
                completion(data, response, error)
            })
        }catch {
            completion(nil, nil, error)
        }
        task?.resume()
    }
    
    func cancel() {
        self.task?.cancel()
    }
    
    fileprivate func createRequest(endpoint: Endpoint) throws -> URLRequest {
        var request = URLRequest(url: endpoint.baseURL.appendingPathComponent(endpoint.path),
                                 cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
                                 timeoutInterval: 10.0)
        request.allHTTPHeaderFields = endpoint.headers
        request.httpBody = endpoint.body
        request.httpMethod = endpoint.httpMethod.rawValue
        return request
    }
}
