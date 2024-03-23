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
                    isThrowing: $0.isThrowing,
                    isStatic: $0.isStatic,
                    closureContents: $0.closureContents
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
                    isThrowing: false,
                    isStatic: false,
                    closureContents: nil
                )
            }
        ]
            .flatMap { $0 }
            .filter { $0.equals == nil }
        
        
        
        
                
        
        
        
        
        
        
        let initParameters = combinedInitParameters
            .filter { $0.closureContents == nil }
        
        let expandedInit: String
        
        if initParameters.isEmpty {
            expandedInit =
                """
                init() {
                
                }
                """
        } else if
            initParameters.count == 1,
            let parameter = initParameters.first
        {
            expandedInit =
                """
                init(\(parameter.name)\(parameter.escapingRhs)) {
                _\(parameter.name) = \(parameter.name)
                }
                """
        } else {
            let args = initParameters
                .map { "\($0.name)\($0.escapingRhs)" }
                .joined(separator: ",\n")
            
            let assigns = initParameters
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
        
        
        
        
        
        
        
        
        
        let productionName = makeProductionInstanceName(from: node)
        
        let typeName = structDecl.name.text
        
        let staticParameters = makeParameterDetails(from: structDecl, includesComputed: false)
        
                
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
        
        
        
        
        
        
        let needsAsync = initParameters
            .contains { $0.isAsync }
        
        let needsThrowing = initParameters
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
            fromCombinedInitParameters: initParameters,
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
        
        
        
        
        
        
        
        
        
        
        
        
        let witnessProperties = combinedInitParameters
            .map {
                let staticOrEmpty = $0.isStatic ? "static " : ""
                
                return "\(staticOrEmpty)var _\($0.name)\($0.rhs)"
            }
            .joined(separator: "\n")
        
        
        
        
        let computedProperties = makeComputedPropertyDetails(from: structDecl)
        
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
                
                let staticOrEmpty = $0.isStatic ? "static " : ""
                let lhs = "\(staticOrEmpty)\($0.letOrVar) \($0.name)"
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
        witnessProperties.isEmpty || expandedComputedProperties.isEmpty ? "" : "\n\n"
        
        let expandedProperties = [
            witnessProperties,
            expandedComputedProperties
        ]
            .joined(separator: expandedPropertiesSeparator)

        
        
        
        
        
        
        
        
        
        
        
        
        
        let productionType = """
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
                
                    \(raw: productionType)
                }
                """
        } else {
            witnessDecl = """
                struct \(raw: witnessTypeName) {
                    \(raw: expandedProperties)
                
                    \(raw: expandedInit)
                
                    \(raw: expandedFunctions)
                
                    \(raw: productionType)
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
                
                let isStatic = member
                    .decl
                    .as(VariableDeclSyntax.self)?
                    .modifiers
                    .contains { $0.name.tokenKind == .keyword(.static) } == true

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
                                isThrowing: isThrowing,
                                isStatic: isStatic
                            )
                        } else if
                            binding
                                .initializer?
                                .value
                                .as(FunctionCallExprSyntax.self)?
                                .calledExpression
                                .as(ClosureExprSyntax.self)?
                                .statements
                                .trimmedDescription
                                != nil
                        {
                            return ComputedPropertyDetails(
                                letOrVar: "var",
                                name: binding.pattern.trimmedDescription,
                                type: type,
                                accessor: "_\(bindingSpecifier.text)",
                                setter: nil,
                                isAsync: false,
                                isThrowing: false,
                                isStatic: isStatic
                            )
                        } else if binding.initializer == nil {
                            return ComputedPropertyDetails(
                                letOrVar: "var",
                                name: binding.pattern.trimmedDescription,
                                type: type,
                                accessor: "_\(bindingSpecifier.text)",
                                setter: nil,
                                isAsync: false,
                                isThrowing: false,
                                isStatic: isStatic
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
                
                let isStatic = member
                    .decl
                    .as(VariableDeclSyntax.self)?
                    .modifiers
                    .contains { $0.name.tokenKind == .keyword(.static) } == true
                
                let accessors = member
                    .decl
                    .as(VariableDeclSyntax.self)?
                    .bindings
                    .first?
                    .accessorBlock?
                    .accessors
                
                let getterClosureContents = accessors?
                    .as(AccessorDeclListSyntax.self)?
                    .first?
                    .body?
                    .statements
                    .trimmedDescription
                
                let functionCallContents = member
                    .decl
                    .as(VariableDeclSyntax.self)?
                    .bindings
                    .first?
                    .initializer?
                    .value
                    .as(FunctionCallExprSyntax.self)?
                    .calledExpression
                    .as(ClosureExprSyntax.self)?
                    .statements
                    .trimmedDescription
                
                let closureContents = functionCallContents
                    ?? getterClosureContents
                    ?? accessors?.trimmedDescription
                
                return varDecl
                    .bindings
                    .compactMap { binding -> ParameterDetails? in
                        let accessorBlock = binding.accessorBlock
                        
                        if
                            includesComputed == false,
                            accessorBlock != nil || closureContents != nil
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
                                isThrowing: isThrowing,
                                isStatic: isStatic,
                                closureContents: closureContents
                            )
                        } else {
                            return ParameterDetails(
                                letOrVar: "var",
                                name: binding.pattern.trimmedDescription,
                                type: nil,
                                equals: binding.initializer?.value.trimmedDescription,
                                isAsync: isAsync,
                                isThrowing: isThrowing,
                                isStatic: isStatic,
                                closureContents: closureContents
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
    let isStatic: Bool
    let closureContents: String?
}


private struct ComputedPropertyDetails {
    let letOrVar: String
    let name: String
    let type: String
    let accessor: String
    let setter: String?
    let isAsync: Bool
    let isThrowing: Bool
    let isStatic: Bool
}


private struct InitParameterDetails {
    let name: String
    let type: String?
    let equals: String?
    let isEscaping: Bool
    let isAsync: Bool
    let isThrowing: Bool
    let isStatic: Bool
    let closureContents: String?
    
    var escapingType: String? {
        guard let type else { return nil }
        
        return isEscaping ? "@escaping \(type)" : type
    }
    
    var rhs: String {
        if isThrowing {
            let typeRhs = closureContents.flatMap { " = { \($0) }" } ?? ""
            
            return type.flatMap { ": () throws -> \($0)\(typeRhs)" } ?? ""
        } else {
            let typeRhs = closureContents.flatMap { " = { \($0) }()" } ?? ""
            
            return type.flatMap { ": \($0)\(typeRhs)" }
                ?? equals.flatMap { " = \($0)" }
                ?? ""
        }
    }
    
    var escapingRhs: String {
        if isThrowing {
            let typeRhs = closureContents.flatMap { " = { \($0) }" } ?? ""
            
            return type.flatMap { ": @escaping () throws -> \($0)\(typeRhs)" } ?? ""
        } else {
            let typeRhs = closureContents.flatMap { " = { \($0) }()" } ?? ""
            
            return escapingType.flatMap { ": \($0)\(typeRhs)" }
                ?? equals.flatMap { " = \($0)" }
                ?? ""
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
