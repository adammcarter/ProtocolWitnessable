import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics


@main
struct ProtocolWitnessingPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        WitnessingMacro.self,
    ]
}



public struct WitnessingMacro: MemberMacro {
    /**
            Create the `Witness` inner type
     */
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let structDecl = declaration as? StructDeclSyntax else {
            WitnessingDiagnostic.notAStruct.diagnose(in: declaration, for: context)
            
            return []
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
                    isAsync: $0.isAsync,
                    isThrowing: $0.isThrowing
                )
            }
            +
            functions.map {
                InitParameterDetails(
                    name: $0.name, 
                    type: $0.type,
                    equals: nil,
                    isEscaping: true,
                    isAsync: false,
                    isThrowing: false
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
                let asyncThrows = if $0.isAsync, $0.isThrowing {
                    " async throws"
                } else if $0.isAsync {
                    " async"
                } else if $0.isThrowing {
                    " throws"
                } else {
                    ""
                }
                
                let getExpression = if $0.isAsync, $0.isThrowing {
                    "try await _\($0.name)()"
                } else if $0.isThrowing {
                    "try _\($0.name)()"
                } else {
                    "_\($0.name)"
                }
                
                let lhs = "\($0.letOrVar) \($0.name)"
                let rhs = "\($0.type)"
                let getName = "get\(asyncThrows)"
                let get = "\(getName) { \(getExpression) }"
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
        
        
        
        
        
        
        let productionName = makeProductionInstanceName(from: node)
        
        let typeName = structDecl.name.text
        
        let staticParameters = makeParameterDetails(from: structDecl, includesComputed: false)
        
        
        let allParameters = makeParameterDetails(from: structDecl, includesComputed: true)
                
        
        let expandedParameters = staticParameters
            .filter { $0.equals == nil }
            .map {
                "\($0.name): \($0.type ?? "")"
            }
            .joined(separator: ",\n")
        
        let expandedPropertiesProduction = staticParameters
            .filter { $0.equals == nil }
            .map {
                "\($0.name): \($0.name)"
            }
            .joined(separator: ",\n")
        
        
        
        
        
        
        let needsAsync = combinedInitParameters
            .contains { $0.isAsync }
        
        let needsThrowing = combinedInitParameters
            .contains { $0.isThrowing }
        
        let asyncThrowsSuffix = if needsAsync, needsThrowing {
            " async throws"
        } else if needsAsync {
            " async"
        } else if needsThrowing {
            " throws"
        } else {
            ""
        }
        
        
        
        
        
        
        let functionPrefix = "static func \(productionName)"
        let functionSuffix = "\(asyncThrowsSuffix) -> \(typeName).\(witnessTypeName)"
        
        let productionFunctionDeclaration = if expandedParameters.isEmpty {
            """
            \(functionPrefix)()\(functionSuffix) {
            """
        } else {
            """
            \(functionPrefix)(
                \(expandedParameters)
            )\(functionSuffix) {
            """
        }
        
        
        
        
        
        
        let productionPropertyLhs = "let \(productionName) = _\(productionName) ?? \(typeName)"
        
        let productionPropertyDeclaration = if expandedPropertiesProduction.isEmpty {
            """
            \(productionPropertyLhs)()
            """
        } else if expandedPropertiesProduction.count == 1, let expandedProperty = expandedPropertiesProduction.first {
            """
            \(productionPropertyLhs)(\(expandedProperty))
            """
        } else {
            """
            \(productionPropertyLhs)(
            \(expandedPropertiesProduction)
            )
            """
        }
        
        
        
        
        
        
        
        let expandedProductionPropertiesWithProductionNamespace = makeExpandedProductionProperties(
            fromCombinedInitParameters: combinedInitParameters,
            productionName: productionName
        )
        
        
        let returnWitnessInitDeclarationLhs = "return \(typeName).\(witnessTypeName)"
        
        let returnWitnessInitDeclaration = if expandedProductionPropertiesWithProductionNamespace.isEmpty {
            """
            \(returnWitnessInitDeclarationLhs)()
            """
        } else {
            """
            \(returnWitnessInitDeclarationLhs)(
            \(expandedProductionPropertiesWithProductionNamespace)
            )
            """
        }
        
        
        
        
        
        let productionValues = """
            private static var _\(productionName): \(typeName)?
            
            \(productionFunctionDeclaration)
            \(productionPropertyDeclaration)
            
            if _\(productionName) == nil {
            _\(productionName) = \(productionName)
            }
            
            \(returnWitnessInitDeclaration)
            }
            """
        
        
        
        

        
        
        let witnessDecl: DeclSyntax
        
        if expandedProperties.isEmpty {
            witnessDecl = """
                struct \(raw: witnessTypeName) {
                    \(raw: expandedInit)
                
                    \(raw: productionValues)
                }
                """
        } else {
            witnessDecl = """
                struct \(raw: witnessTypeName) {
                    \(raw: expandedProperties)
                
                    \(raw: expandedInit)
                
                    \(raw: expandedFunctions)
                
                    \(raw: productionValues)
                }
                """
        }
        
        return [witnessDecl]
    }
    
    
    
    
    
    private static func makeExpandedProductionProperties(
        fromCombinedInitParameters combinedInitParameters: [InitParameterDetails],
        productionName: String?
    ) -> String {
        combinedInitParameters
            .map { parameter -> String in
                let asyncThrows = if parameter.isAsync, parameter.isThrowing {
                    " try await"
                } else if parameter.isAsync {
                    " await"
                } else if parameter.isThrowing {
                    " try"
                } else {
                    ""
                }
                
                let propertyName = productionName.flatMap { "\($0).\(parameter.name)" } ?? parameter.name
                let value = "\(asyncThrows) \(propertyName)"
                let rhs = parameter.isThrowing ? "{ \(value) }" : value
                
                return "\(parameter.name):\(rhs)"
            }
            .joined(separator: ",\n")
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
                
                let bindingSpecifier = varDecl.bindingSpecifier
                
                return varDecl
                    .bindings
                    .compactMap { binding -> ComputedPropertyDetails? in
                        guard
                            let type = binding.typeAnnotation?.type.trimmedDescription
                        else {
                            return nil
                        }
                        
                        if let accessorBlock = binding.accessorBlock {
                            let isAsync = accessorBlock
                                .accessors
                                .as(AccessorDeclListSyntax.self)?
                                .compactMap { $0.effectSpecifiers?.asyncSpecifier }
                                .isEmpty == false
                            
                            let isThrowing = accessorBlock
                                .accessors
                                .as(AccessorDeclListSyntax.self)?
                                .compactMap { $0.effectSpecifiers?.throwsSpecifier }
                                .isEmpty == false
                            
                            let setter = accessorBlock
                                .accessors
                                .as(AccessorDeclListSyntax.self)?
                                .first { $0.accessorSpecifier.tokenKind == .keyword(.set) }
                            
                            return ComputedPropertyDetails(
                                letOrVar: bindingSpecifier.text,
                                name: binding.pattern.trimmedDescription,
                                type: type,
                                accessor: accessorBlock.trimmedDescription,
                                setter: setter?.trimmedDescription,
                                isAsync: isAsync,
                                isThrowing: isThrowing
                            )
                        } else if binding.initializer == nil {
                            return ComputedPropertyDetails(
                                letOrVar: "var",
                                name: binding.pattern.trimmedDescription,
                                type: type,
                                accessor: "_\(bindingSpecifier.text)",
                                setter: nil,
                                isAsync: false,
                                isThrowing: false
                            )
                        } else {
                            return nil
                        }
                        
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
                        let accessorBlock = binding.accessorBlock
                        
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
                        
                        let isThrowing = accessorBlock?
                            .accessors
                            .as(AccessorDeclListSyntax.self)?
                            .compactMap { $0.effectSpecifiers?.throwsSpecifier }
                            .isEmpty == false

                        if let type = binding.typeAnnotation?.type.trimmedDescription {
                            return ParameterDetails(
                                letOrVar: letOrVar,
                                name: binding.pattern.trimmedDescription,
                                type: type,
                                equals: nil,
                                isAsync: isAsync,
                                isThrowing: isThrowing
                            )
                        } else {
                            return ParameterDetails(
                                letOrVar: "var",
                                name: binding.pattern.trimmedDescription,
                                type: nil,
                                equals: binding.initializer?.value.trimmedDescription,
                                isAsync: isAsync,
                                isThrowing: isThrowing
                            )
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
                
                let isThrows = signature
                    .effectSpecifiers?
                    .throwsSpecifier != nil
                
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
                
                
                
                let signatureDecl = if isAsync, isThrows {
                    "(\(parameterTypesList)) async throws"
                } else if isAsync {
                    "(\(parameterTypesList)) async"
                } else if isThrows {
                    "(\(parameterTypesList)) throws"
                } else {
                    "(\(parameterTypesList))"
                }
                
                
                let signatureParameterNamesDecl = if isAsync, isThrows {
                    "(\(parameterNameWithTypeList)) async throws"
                } else if isAsync {
                    "(\(parameterNameWithTypeList)) async"
                } else if isThrows {
                    "(\(parameterNameWithTypeList)) throws"
                } else {
                    "(\(parameterNameWithTypeList))"
                }
                
                
                let tryAwaitOrEmpty = if isAsync, isThrows {
                    "try await "
                } else if isAsync {
                    "await "
                } else if isThrows {
                    "try "
                } else {
                    ""
                }
                
                return FunctionDetails(
                    name: name,
                    type: "\(signatureDecl) -> \(returnValueOrVoid)",
                    callsite:
                        """
                        func \(name)\(signatureParameterNamesDecl)\(returnValueIfNotVoid) {
                        \(tryAwaitOrEmpty)_\(name)(\(parameterNameWithNameList))
                        }
                        """
                )
            }
    }
    
    
    
    private static func makeWitnessTypeName(from node: AttributeSyntax) -> String {
        let defaultName = "ProtocolWitness"
        
        return node
            .arguments?
            .as(LabeledExprListSyntax.self)?
            .first { $0.label?.text == "typeName" }?
            .expression
            .as(StringLiteralExprSyntax.self)?
            .segments
            .first?
            .as(StringSegmentSyntax.self)?
            .content
            .text
        ?? defaultName
    }
    
    
    private static func makeProductionInstanceName(from node: AttributeSyntax) -> String {
        node
            .arguments?
            .as(LabeledExprListSyntax.self)?
            .first(where: { $0.label?.text == "productionInstanceName" })?
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
    let isThrowing: Bool
}


private struct ComputedPropertyDetails {
    let letOrVar: String
    let name: String
    let type: String
    let accessor: String
    let setter: String?
    let isAsync: Bool
    let isThrowing: Bool
}


private struct InitParameterDetails {
    let name: String
    let type: String?
    let equals: String?
    let isEscaping: Bool
    let isAsync: Bool
    let isThrowing: Bool
    
    var escapingType: String? {
        guard let type else { return nil }
        
        return isEscaping ? "@escaping \(type)" : type
    }
    
    var rhs: String {
        if isThrowing {
            type.flatMap { ": () throws -> \($0)" } ?? ""
        } else {
            type.flatMap { ": \($0)" } ?? equals.flatMap { " = \($0)" } ?? ""
        }
    }
    
    var escapingRhs: String {
        if isThrowing {
            type.flatMap { ": @escaping () throws -> \($0)" } ?? ""
        } else {
            escapingType.flatMap { ": \($0)" } ?? equals.flatMap { " = \($0)" } ?? ""
        }
    }
}



private enum WitnessingDiagnostic: String, DiagnosticMessage {
    case notAStruct
    
    var severity: DiagnosticSeverity { .error }
    
    var message: String {
        switch self {
            case .notAStruct:
                return "'@ProtocolWitnessing' can only be attached to a 'struct'"
        }
    }
    
    var diagnosticID: MessageID {
        MessageID(domain: "ProtocolWitnessingMacro", id: rawValue)
    }
    
    func diagnose(in node: some DeclGroupSyntax, for context: some MacroExpansionContext) {
        let name = node.as(ClassDeclSyntax.self)?.name ?? TokenSyntax(stringLiteral: "Name")
        
        let newNode = StructDeclSyntax(leadingTrivia: node.leadingTrivia, attributes: node.attributes, modifiers: node.modifiers, structKeyword: "\nstruct ", name: name, genericParameterClause: nil, inheritanceClause: node.inheritanceClause, genericWhereClause: node.genericWhereClause, memberBlock: node.memberBlock, trailingTrivia: node.trailingTrivia)
        
        context.diagnose(
            .init(
                node: node,
                message: self,
                fixIt: .replace(
                    message: MyFitItMessage.notAStruct,
                    oldNode: node,
                    newNode: newNode
                )
            )
        )
    }
}

enum MyFitItMessage: FixItMessage {
    case notAStruct
    
    var message: String {
        "Replace"
    }
    
    var fixItID: MessageID {
        MessageID(domain: "ProtocolWitnessingMacro", id: message)
    }
}
