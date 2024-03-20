import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros


@main
struct ProtocolWitnessingPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        WitnessingMacro.self,
    ]
}



public struct WitnessingMacro: MemberMacro, ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let structDecl = declaration as? StructDeclSyntax else {
            throw WitnessingError.structOnly
        }
        
        
        let parameters = makeParameterDetails(from: structDecl)
        
        let functions = makeFunctionDetails(from: structDecl)
        
        let combinedInitParameters: [InitParameterDetails] = [
            parameters.map {
                InitParameterDetails(name: $0.name, type: $0.type, isEscaping: false)
            }
            +
            functions.map {
                InitParameterDetails(name: $0.name, type: $0.type, isEscaping: true)
            }
        ].flatMap { $0 }
        
        
        
        
        let expandedProperties = combinedInitParameters
            .map {
                "var _\($0.name): \($0.type)"
            }
            .joined(separator: "\n")
        
        
        
        
        
        
        
        let expandedInit: String
        
        if combinedInitParameters.isEmpty {
            expandedInit =
                """
                init() {
                
                }
                """
        } else if combinedInitParameters.count == 1, let parameter = combinedInitParameters.first {
            expandedInit =
                """
                init(\(parameter.name): \(parameter.escapingType)) {
                _\(parameter.name) = \(parameter.name)
                }
                """
        } else {
            let args = combinedInitParameters
                .map { "\($0.name): \($0.escapingType)" }
                .joined(separator: ",\n")
            
            let assigns = combinedInitParameters
                .map { "_\($0.name) = \($0.name)" }
                .joined(separator: "\n")
            
            expandedInit = 
                """
                init(
                \(args)
                ) {
                \(assigns)
                }
                """
        }
        
        
        
        let witnessTypeName = makeWitnessTypeName(from: node)
        
        
        let expandedFunctions = functions
            .map {
                $0.callsite
            }
            .joined(separator: "\n\n")
        
        
        
        let witnessDecl: DeclSyntax
        
        if expandedProperties.isEmpty {
            witnessDecl = """
                struct \(raw: witnessTypeName) {
                    \(raw: expandedInit)
                }
                """
        } else {
            witnessDecl = """
                struct \(raw: witnessTypeName) {
                    \(raw: expandedProperties)
                    
                    \(raw: expandedInit)
                    
                    \(raw: expandedFunctions)
                }
                """
        }
        
        return [witnessDecl]
    }
    
    
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard let structDecl = declaration as? StructDeclSyntax else {
            throw WitnessingError.structOnly
        }

        let productionName = makeProductionInstanceName(from: node)

        let typeName = structDecl.name.text
        let witnessTypeName = makeWitnessTypeName(from: node)
        
        let parameters = makeParameterDetails(from: structDecl)
        
        let functions = makeFunctionDetails(from: structDecl)
        
        let combinedInitParameters: [InitParameterDetails] = [
            parameters.map {
                InitParameterDetails(name: $0.name, type: $0.type, isEscaping: false)
            }
            +
            functions.map {
                InitParameterDetails(name: $0.name, type: $0.type, isEscaping: true)
            }
        ].flatMap { $0 }

        let expandedParameters = parameters
            .map {
                "\($0.name): \($0.type)"
            }
            .joined(separator: ",\n")

        let expandedProperties = parameters
            .map {
                "\($0.name): \($0.name)"
            }
            .joined(separator: ",\n")
        
        let expandedProductionProperties = combinedInitParameters
            .map {
                "\($0.name): \(productionName).\($0.name)"
            }
            .joined(separator: ",\n")
        
        
        
        
        
        let productionFunctionDeclaration = if expandedParameters.isEmpty {
            """
            static func \(productionName)() -> \(typeName).\(witnessTypeName) {
            """
        } else {
            """
            static func \(productionName)(
                \(expandedParameters)
            ) -> \(typeName).\(witnessTypeName) {
            """
        }
        
        
        
        let productionPropertyDeclaration = if expandedProperties.isEmpty {
            """
            let \(productionName) = _\(productionName) ?? \(typeName)()
            """
        } else {
            """
            let \(productionName) = _\(productionName) ?? \(typeName)(
            \(expandedProperties)
            )
            """
        }
        
        
        return [
            try ExtensionDeclSyntax(
                """
                extension \(raw: typeName) {
                private static var _\(raw: productionName): \(raw: typeName)?
                
                \(raw: productionFunctionDeclaration)
                \(raw: productionPropertyDeclaration)
                
                if _\(raw: productionName) == nil {
                _\(raw: productionName) = \(raw: productionName)
                }
                
                return \(raw: typeName).\(raw: witnessTypeName)(
                \(raw: expandedProductionProperties)
                )
                }
                }
                """
            )
        ]
    }
    
    
    
    
    private static func makeParameterDetails(from structDecl: StructDeclSyntax) -> [ParameterDetails] {
        structDecl
            .memberBlock
            .members
            .compactMap { member -> [ParameterDetails]? in
                guard
                    let varDecl = member
                        .decl
                        .as(VariableDeclSyntax.self)
                else {
                    return nil
                }
                
                let letOrVar = varDecl.bindingSpecifier.text
                
                return varDecl
                    .bindings
                    .compactMap { binding -> ParameterDetails? in
                        guard let type = binding.typeAnnotation?.type.description else {
                            return nil
                        }
                        
                        return ParameterDetails(
                            letOrVar: letOrVar,
                            name: binding.pattern.description,
                            type: type
                        )
                    }
            }
            .flatMap { $0 }
    }
    
    
    
    
    private static func makeFunctionDetails(from structDecl: StructDeclSyntax) -> [FunctionDetails] {
        structDecl.memberBlock.members
            .compactMap { $0.decl.as(FunctionDeclSyntax.self) }
            .map {
                let parameterDetails = $0
                    .signature
                    .parameterClause
                    .parameters
                    .compactMap {
                        ClosureParameterDetails(
                            name: $0.firstName.text,
                            type: $0.type.description
                        )
                    }
                
                
                
                let parameterTypesList = parameterDetails
                    .map(\.type)
                    .joined(separator: ", ")
                
                let parameterNameWithTypeList = parameterDetails
                    .map { "\($0.name): \($0.type)" }
                    .joined(separator: ", ")
                
                
                let parameterNameWithNameList = parameterDetails
                    .map { "\($0.name)" }
                    .joined(separator: ", ")
                
                
                
                
                
                let returnValue = $0
                    .signature
                    .returnClause?
                    .type
                    .as(IdentifierTypeSyntax.self)?
                    .name
                    .text
                
                let name = $0.name.text
                
                let returnValueOrVoid = returnValue ?? "Void"
                let returnValueIfNotVoid = returnValue.flatMap { " -> \($0)" } ?? ""
                
                
                
                
                
                return FunctionDetails(
                    name: name,
                    type: "(\(parameterTypesList)) -> \(returnValueOrVoid)",
                    callsite:
                        """
                        func \(name)(\(parameterNameWithTypeList))\(returnValueIfNotVoid) {
                        _\(name)(\(parameterNameWithNameList))
                        }
                        """
                )
            }
    }
    
    
    
    private static func makeWitnessTypeName(from node: AttributeSyntax) -> String {
        let labeledExpression = node
            .arguments?
            .as(LabeledExprListSyntax.self)?
            .first?
            .as(LabeledExprSyntax.self)
        
        guard labeledExpression?.label == nil else {
            return "Witness"
        }
        
        return labeledExpression?
            .expression
            .as(StringLiteralExprSyntax.self)?
            .segments
            .first?
            .as(StringSegmentSyntax.self)?
            .content
            .text
        ?? "Witness"
    }
    
    
    private static func makeProductionInstanceName(from node: AttributeSyntax) -> String {
        node
            .arguments?
            .as(LabeledExprListSyntax.self)?
            .first(where: { $0.as(LabeledExprSyntax.self)?.label?.text == "productionInstanceName" })?
            .expression
            .as(StringLiteralExprSyntax.self)?
            .segments
            .first?
            .as(StringSegmentSyntax.self)?
            .content
            .text
        ?? "production"
    }

}


private struct FunctionDetails {
    let name: String
    let type: String
    let callsite: String
}


private struct ClosureParameterDetails {
    let name: String
    let type: String
}


private struct ParameterDetails {
    let letOrVar: String
    let name: String
    let type: String
}


private struct InitParameterDetails {
    let name: String
    let type: String
    let isEscaping: Bool
    
    var escapingType: String {
        isEscaping ? "@escaping \(type)" : type
    }
}

private enum WitnessingError: Error, CustomStringConvertible {
    case structOnly
    
    var description: String {
        switch self {
            case .structOnly: "@Witnessing can only be attached to a struct"
        }
    }
}
