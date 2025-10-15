//
//  RestClient+APIDefinition.swift
//  
//
//  Created by Bill Gestrich on 7/19/21.
//

import Foundation

public typealias EmptyCodable = Dictionary<String,String>

public protocol RestAPI {
    var pathComponents: [String] { get }
    var parentPath: String { get }
    func path() -> String
    
    func formPath(parentPath: String, thisPathComponent: String) -> String
}

public extension RestAPI {
    //TODO: Get rid of this
    func formPath(parentPath: String, thisPathComponent: String) -> String {
        return [parentPath, thisPathComponent].compactMap({$0.count > 0 ? $0 : nil}).joined(separator: "/")
        //return self.pathComponents.compactMap({$0.count > 0 ? $0 : nil }).joined(separator: "/")
    }
    
    func path() -> String {
        if let lastPath = self.pathComponents.last {
            return self.formPath(parentPath: self.parentPath, thisPathComponent: lastPath)
        } else {
            return self.parentPath
        }

    }
}

public class PathComponentBuilder {
    private var components = [String]()
    
    init(){
        
    }
    
    func addComponent(_ component: String) {
        components.append(component)
    }
    
    func getComponents() -> [String] {
        return components
    }
}

public enum MethodType {
    case Get
    case Post
    case None
}

public protocol APIDefinition: RestAPI {
    var method: MethodType { get }
    associatedtype In: Codable
    associatedtype Out: Codable
    
    func convertJSONData(_ data: Data) throws -> Out
}

extension APIDefinition {
    public func convertJSONData(_ data: Data) throws -> Out {
        return try JSONDecoder().decode(Out.self, from: data)
    }
}


public struct AnyAPIDefinition<In: Codable, Out: Codable>: APIDefinition {
    public var pathComponents: [String]
    public var parentPath: String
    public let method: MethodType
    
    private let convertJSONData: (Data) throws -> Out
    
    //typealias In = In
    //typealias Out = Out
    
    public init<Definition: APIDefinition>(wrappedDefinition: Definition) where Definition.Out == Out, Definition.In == In {
        self.convertJSONData = wrappedDefinition.convertJSONData
        self.pathComponents = wrappedDefinition.pathComponents
        self.parentPath = wrappedDefinition.parentPath
        self.method = wrappedDefinition.method
    }
    
    public func convertJSONData(_ data: Data) throws -> Out {
        return try convertJSONData(data)
    }
}

extension RestClient {

    public func performAPIOperation<T: APIDefinition>(input: T.In, apiDef: T) async throws -> T.Out {
        let data: Data

        switch apiDef.method {
        case .Get:
            data = try await self.getData(relativeURL: apiDef.path())
        case .Post:
            data = try await self.peformJSONPost(relativeURL: apiDef.path(), payload: input)
        case .None:
            fatalError("Can't perform None operation")
        }

        return try apiDef.convertJSONData(data)
    }
}
