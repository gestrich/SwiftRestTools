//
//  RestClient.swift
//  swift-utilities
//
//  Created by Bill Gestrich on 10/29/17.
//  Copyright © 2017 Bill Gestrich. All rights reserved.
//

import Foundation

public enum RestClientError: Error, Sendable {
    case missingResponse
    case returnDataType
    case serviceError(Error)
    case statusCode(_ code: Int, _ body: String?)
    case noData
    case deserialization(Error)
}

open class RestClient: NSObject, @unchecked Sendable {

    let baseURL: String
    open var headers: [String:String]?
    var auth : BasicAuth?
    
    public init(baseURL: String){
        self.baseURL = baseURL
        super.init()
    }
    
    public convenience init(baseURL: String, auth: BasicAuth){
        self.init(baseURL: baseURL)
        self.auth = auth
    }
    
    public convenience init(baseURL: String, auth: BasicAuth?, headers:[String:String]?){
        self.init(baseURL: baseURL)
        self.auth = auth
        self.headers = headers
    }
    
    public func getData(relativeURL: String) async throws -> Data {
        let urlString = baseURL.appending(relativeURL)
        return try await getData(fullURL: urlString)
    }

    public func getData(fullURL: String) async throws -> Data {
        var headersToSet = ["Content-Type":"application/json", "Accept":"application/json"]
        if let headers = self.headers {
            headersToSet += headers
        }
        let http = SimpleHttp(auth:self.auth, headers:headersToSet)
        let url = URL(string: fullURL)!
        return try await http.getData(url: url)
    }
    
    public func peformJSONPost<T>(relativeURL: String, payload: T) async throws -> Data where T : Encodable {
        let urlString = baseURL.appending(relativeURL)
        return try await peformJSONPost(fullURL: urlString, payload: payload)
    }

    public func peformJSONPost<T>(fullURL: String, payload: T) async throws -> Data where T : Encodable {
        var headersToSet = ["Content-Type":"application/json", "Accept":"application/json"]
        if let headers = self.headers {
            headersToSet += headers
        }
        let http = SimpleHttp(auth:self.auth, headers:headersToSet)
        let url = URL(string: fullURL)!
        return try await http.peformJSONPost(url: url, payload: payload)
    }

    public func uploadFile(filePath: String, relativeDestinationPath: String) async throws -> Data {
        let fullDestinationPath = baseURL.appending(relativeDestinationPath)
        return try await uploadFile(filePath: filePath, fullDestinationPath: fullDestinationPath)
    }

    public func uploadFile(filePath: String, fullDestinationPath: String) async throws -> Data {
        var headersToSet = ["Accept":"application/json", "X-Atlassian-Token":"nocheck"]
        if let headers = self.headers {
            headersToSet += headers
        }
        let http = SimpleHttp(auth:self.auth, headers:headersToSet)
        let destinationURL = URL(string: fullDestinationPath)!
        let fileURL = URL(string: filePath)!
        return try await http.uploadFile(fileUrl: fileURL, destinationURL: destinationURL)
    }
    
    public func fullURLWithRelativeURL(relativeURL: String) -> String {
        return baseURL.appending(relativeURL)
    }
    
}
