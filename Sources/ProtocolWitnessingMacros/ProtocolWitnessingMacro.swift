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
        
        
        
        
        let parameters = makeParameterDetails(from: structDecl, includesComputed: true)
        
        let functions = makeFunctionDetails(from: structDecl)
        
        let combinedInitParameters: [InitParameterDetails] = [
            parameters.map {
                InitParameterDetails(
                    name: $0.name, 
                    type: $0.type,
                    equals: $0.equals,
                    isEscaping: false,
                    isAsync: $0.isAsync
                )
            }
            +
            functions.map {
                InitParameterDetails(
                    name: $0.name, 
                    type: $0.type,
                    equals: nil,
                    isEscaping: true,
                    isAsync: false
                )
            }
        ]
            .flatMap { $0 }
            .filter { $0.equals == nil }
        
        
        
        
        
        
        let computedProperties = makeComputedPropertyDetails(from: structDecl)
        
        
        
        
        
        
        
        
        let expandedInit: String
        
        if combinedInitParameters.isEmpty {
            expandedInit =
                """
                init() {
                
                }
                """
        } else if
            combinedInitParameters.count == 1,
            let parameter = combinedInitParameters.first
        {
            expandedInit =
                """
                init(\(parameter.name)\(parameter.escapingRhs)) {
                _\(parameter.name) = \(parameter.name)
                }
                """
        } else {
            let args = combinedInitParameters
                .map { "\($0.name)\($0.escapingRhs)" }
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
        
        
        
        
        
        
        
        
        let expandedInitParameters = combinedInitParameters
            .map {
                "var _\($0.name)\($0.rhs)"
            }
            .joined(separator: "\n")
        
        
        let expandedComputedProperties = computedProperties
            .map {
                let lhs = "\($0.letOrVar) \($0.name)"
                let rhs = "\($0.type)"
                let getName = "get\($0.isAsync ? " async" : "")"
                let get = "\(getName) { _\($0.name) }"
                let set = $0.setter.flatMap { "\n\($0)" } ?? ""
                
                return """
                    \(lhs): \(rhs) {
                    \(get)\(set)
                    }
                    """
            }
            .joined(separator: "\n\n")
        
        
        
        let expandedPropertiesSeparator = 
            expandedInitParameters.isEmpty || expandedComputedProperties.isEmpty ? "" : "\n\n"
        
        let expandedProperties = [
            expandedInitParameters,
            expandedComputedProperties
        ]
            .joined(separator: expandedPropertiesSeparator)

        
        
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
        
        let staticParameters = makeParameterDetails(from: structDecl, includesComputed: false)
        
        
        let allParameters = makeParameterDetails(from: structDecl, includesComputed: true)
        
        let functions = makeFunctionDetails(from: structDecl)
        
        let combinedInitParameters: [InitParameterDetails] = [
            allParameters.map {
                InitParameterDetails(
                    name: $0.name, 
                    type: $0.type,
                    equals: $0.equals,
                    isEscaping: false,
                    isAsync: $0.isAsync
                )
            }
            +
            functions.map {
                InitParameterDetails(
                    name: $0.name,
                    type: $0.type,
                    equals: nil,
                    isEscaping: true,
                    isAsync: false
                )
            }
        ]
            .flatMap { $0 }
            .filter { $0.equals == nil }

        let expandedParameters = staticParameters
            .filter { $0.equals == nil }
            .map {
                "\($0.name): \($0.type ?? "")"
            }
            .joined(separator: ",\n")

        let expandedProperties = staticParameters
            .filter { $0.equals == nil }
            .map {
                "\($0.name): \($0.name)"
            }
            .joined(separator: ",\n")
        
        let expandedProductionProperties = combinedInitParameters
            .map {
                let async = "\($0.isAsync ? " await" : "")"
                let propertyName = "\(productionName).\($0.name)"
                
                return "\($0.name):\(async) \(propertyName)"
            }
            .joined(separator: ",\n")
        
        
        
        let needsAsyncAwait = combinedInitParameters
            .contains { $0.isAsync }
        
        let asyncSuffix = needsAsyncAwait ? " async" : ""
        
        
        
        let productionFunctionDeclaration = if expandedParameters.isEmpty {
            """
            static func \(productionName)()\(asyncSuffix) -> \(typeName).\(witnessTypeName) {
            """
        } else {
            """
            static func \(productionName)(
                \(expandedParameters)
            )\(asyncSuffix) -> \(typeName).\(witnessTypeName) {
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
        
        
        let returnDeclaration = if expandedProductionProperties.isEmpty {
            """
            return \(typeName).\(witnessTypeName)()
            """
        } else {
            """
            return \(typeName).\(witnessTypeName)(
            \(expandedProductionProperties)
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
                
                \(raw: returnDeclaration)
                }
                }
                """
            )
        ]
    }
    
    
    
    
    private static func makeComputedPropertyDetails(from structDecl: StructDeclSyntax) -> [ComputedPropertyDetails] {
        structDecl
            .memberBlock
            .members
            .compactMap { member -> [ComputedPropertyDetails]? in
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
                    .compactMap { binding -> ComputedPropertyDetails? in
                        guard 
                            let pattern = binding.as(PatternBindingSyntax.self),
                            let type = binding.typeAnnotation?.type.trimmedDescription,
                            let accessorBlock = pattern.accessorBlock
                        else {
                            return nil
                        }
                        
                        let isAsync = accessorBlock
                            .accessors
                            .as(AccessorDeclListSyntax.self)?
                            .compactMap { $0.effectSpecifiers?.asyncSpecifier }
                            .isEmpty == false
                        
                        let setter = accessorBlock
                            .accessors
                            .as(AccessorDeclListSyntax.self)?
                            .first { $0.accessorSpecifier.tokenKind == .keyword(.set) }
                        
                        return ComputedPropertyDetails(
                            letOrVar: letOrVar,
                            name: binding.pattern.trimmedDescription,
                            type: type,
                            accessor: accessorBlock.trimmedDescription,
                            setter: setter?.trimmedDescription,
                            isAsync: isAsync
                        )
                    }
            }
            .flatMap { $0 }
    }
    
    
    
    
    
    private static func makeParameterDetails(from structDecl: StructDeclSyntax, includesComputed: Bool) -> [ParameterDetails] {
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
                        let accessorBlock = binding.as(PatternBindingSyntax.self)?.accessorBlock
                        
                        if
                            includesComputed == false,
                            accessorBlock != nil
                        {
                            return nil
                        }
                        
                        
                        let isAsync = accessorBlock?
                            .accessors
                            .as(AccessorDeclListSyntax.self)?
                            .compactMap { $0.effectSpecifiers?.asyncSpecifier }
                            .isEmpty == false

                        if let type = binding.typeAnnotation?.type.trimmedDescription {
                            return ParameterDetails(
                                letOrVar: letOrVar,
                                name: binding.pattern.trimmedDescription,
                                type: type,
                                equals: nil,
                                isAsync: isAsync
                            )
                        } else if binding.is(PatternBindingSyntax.self) {
                            return ParameterDetails(
                                letOrVar: "var",
                                name: binding.pattern.trimmedDescription,
                                type: nil,
                                equals: binding.initializer?.value.trimmedDescription,
                                isAsync: isAsync
                            )
                        } else {
                            return nil
                        }
                    }
            }
            .flatMap { $0 }
    }
    
    
    
    
    private static func makeFunctionDetails(from structDecl: StructDeclSyntax) -> [FunctionDetails] {
        structDecl.memberBlock.members
            .compactMap { $0.decl.as(FunctionDeclSyntax.self) }
            .map {
                let signature = $0.signature
                
                let isAsync = signature
                    .effectSpecifiers?
                    .asyncSpecifier != nil
                
                let parameterDetails = signature
                    .parameterClause
                    .parameters
                    .compactMap {
                        ClosureParameterDetails(
                            name: $0.firstName.text,
                            type: $0.type.description
                        )
                    }
                
                
                
                let parameterTypesList = parameterDetails
                    .map { $0.type }
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
                
                
                
                let signatureDecl = if isAsync {
                    "(\(parameterTypesList)) async"
                } else {
                    "(\(parameterTypesList))"
                }
                
                
                let signatureParameterNamesDecl = if isAsync {
                    "(\(parameterNameWithTypeList)) async"
                } else {
                    "(\(parameterNameWithTypeList))"
                }
                
                
                let awaitOrEmpty = if isAsync {
                    "await "
                } else {
                    ""
                }
                
                return FunctionDetails(
                    name: name,
                    type: "\(signatureDecl) -> \(returnValueOrVoid)",
                    callsite:
                        """
                        func \(name)\(signatureParameterNamesDecl)\(returnValueIfNotVoid) {
                        \(awaitOrEmpty)_\(name)(\(parameterNameWithNameList))
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
    let type: String?
    let equals: String?
    let isAsync: Bool
}


private struct ComputedPropertyDetails {
    let letOrVar: String
    let name: String
    let type: String
    let accessor: String
    let setter: String?
    let isAsync: Bool
}


private struct InitParameterDetails {
    let name: String
    let type: String?
    let equals: String?
    let isEscaping: Bool
    let isAsync: Bool
    
    var escapingType: String? {
        guard let type else { return nil }
        
        return isEscaping ? "@escaping \(type)" : type
    }
    
    var rhs: String {
        type.flatMap { ": \($0)" } ?? equals.flatMap { " = \($0)" } ?? ""
    }
    
    var escapingRhs: String {
        escapingType.flatMap { ": \($0)" } ?? equals.flatMap { " = \($0)" } ?? ""
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
