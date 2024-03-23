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
        
        let protocolWitnessName = makeProductionInstanceName(from: node)
        let typeName = structDecl.name.text
        let witnessTypeName = makeWitnessTypeName(from: node)

        
        
        let capturedProperties = makeCapturedProperties(from: structDecl)
        let capturedFunctions = makeCapturedFunctions(from: structDecl)
        
        
        
        
        
        
        
        
        
        
        let allInitializerParameters: [InitializerParameter] = [
            capturedProperties.map {
                InitializerParameter(
                    modifier: $0.modifier,
                    letOrVar: $0.letOrVar,
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
            capturedFunctions.map {
                InitializerParameter(
                    modifier: $0.modifier,
                    letOrVar: nil,
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
            .filter { $0.closureContents == nil }
            .filter { $0.equals == nil }

        
        
        let protocolWitnessInit: String
        
        if allInitializerParameters.isEmpty {
            protocolWitnessInit = """
                init() {
                
                }
                """
        } else if
            allInitializerParameters.count == 1,
            let parameter = allInitializerParameters.first
        {
            protocolWitnessInit = """
                init(\(parameter.name)\(parameter.escapingRhs)) {
                _\(parameter.name) = \(parameter.name)
                }
                """
        } else {
            let arguments = allInitializerParameters
                .map { "\($0.name)\($0.escapingRhs)" }
                .joined(separator: ",\n")
            
            let assigns = allInitializerParameters
                .map { "_\($0.name) = \($0.name)" }
                .joined(separator: "\n")
            
            protocolWitnessInit = """
                init(
                \(arguments)
                ) {
                \(assigns)
                }
                """
        }
        
        
        
        
        let protocolWitnessInitializerParameters = makeProtocolWitnessInitializerParameters(
            from: allInitializerParameters,
            productionName: protocolWitnessName
        )
        
        
        let returnProtocolWitnessInitFunctionName = "return \(typeName).\(witnessTypeName)"
        
        let returnProtocolWitnessInitializer = if protocolWitnessInitializerParameters.isEmpty {
            """
            \(returnProtocolWitnessInitFunctionName)()
            """
        } else {
            """
            \(returnProtocolWitnessInitFunctionName)(
            \(protocolWitnessInitializerParameters)
            )
            """
        }
        
        
        
        
        
        
        
        
        
        
        
        
        let propertiesFromProtocolWitnessProperties = capturedProperties
            .compactMap(makeProtocolWitnessProperties)
            .joined(separator: "\n\n")
        
        
        let propertiesFromProtocolWitnessFunctions = capturedFunctions
            .map(makeProtocolWitnessProperties)
            .joined(separator: "\n\n")

        
        let propertiesSeparator =
            propertiesFromProtocolWitnessProperties.isEmpty
            || propertiesFromProtocolWitnessFunctions.isEmpty
            ? "" : "\n\n"
        
        let allProtocolWitnessProperties = [
            propertiesFromProtocolWitnessProperties,
            propertiesFromProtocolWitnessFunctions,
        ]
            .joined(separator: propertiesSeparator)
        
        
        
        
        let nonComputedParameters = capturedProperties
            .filter { $0.isComputed == false }
    
        let expandedParameters = nonComputedParameters
            .filter { $0.equals == nil }
            .map {
                "\($0.name): \($0.type ?? "")"
            }
            .joined(separator: ",\n")

        
        
        let isMainActor = declGroupIsMainActor(structDecl)
        let mainActorOrEmpty = isMainActor ? "@MainActor\n" : ""
        
        let functionPrefix = "\(mainActorOrEmpty)static func \(protocolWitnessName)"
        
        
        let needsAsync = allInitializerParameters.contains { $0.isAsync }
        let needsThrowing = allInitializerParameters.contains { $0.isThrowing }
        
        let asyncThrowsSuffix = if needsAsync, needsThrowing {
            " async throws"
        } else if needsAsync {
            " async"
        } else if needsThrowing {
            " throws"
        } else {
            ""
        }

        let functionSuffix = "\(asyncThrowsSuffix) -> \(typeName).\(witnessTypeName)"

        
        let staticFuncProductionFunctionDeclaration = if expandedParameters.isEmpty {
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

        
        
        
        
        
        

        
        
        
        let parametersForProtocolWitnessInit = nonComputedParameters
            .filter { $0.equals == nil }
            .map {
                "\($0.name): \($0.name)"
            }
            .joined(separator: ",\n")
        

        
        
        
        let letProductionInit = if parametersForProtocolWitnessInit.isEmpty {
            """
            \(typeName)()
            """
        } else if parametersForProtocolWitnessInit.count == 1, let expandedProperty = parametersForProtocolWitnessInit.first {
            """
            \(typeName)(\(expandedProperty))
            """
        } else {
            """
            \(typeName)(
            \(parametersForProtocolWitnessInit)
            )
            """
        }

        
        
        
        
        
        
        
        let wrappedFunctions = capturedFunctions
            .map {
                let modifierOrEmpty = $0.modifier.flatMap { "\($0) " } ?? ""
                
                return "\(modifierOrEmpty)\($0.callsite)"
            }
            .joined(separator: "\n\n")

        
        
        
        
        
        

        let protocolWitnessStaticVar = """
            private static var _\(protocolWitnessName): \(typeName)?
            """
        
        
        
        let protocolWitnessFunction = """
            \(staticFuncProductionFunctionDeclaration)
            let \(protocolWitnessName) = _\(protocolWitnessName) ?? \(letProductionInit)
            
            if _\(protocolWitnessName) == nil {
            _\(protocolWitnessName) = \(protocolWitnessName)
            }
            
            \(returnProtocolWitnessInitializer)
            }
            """
        
        
        
        
        
        
        let witnessDecl: DeclSyntax
        
        if allProtocolWitnessProperties.isEmpty {
            witnessDecl = """
                struct \(raw: witnessTypeName) {
                    \(raw: protocolWitnessInit)
                
                    \(raw: protocolWitnessStaticVar)
                
                    \(raw: protocolWitnessFunction)
                }
                """
        } else {
            witnessDecl = """
                struct \(raw: witnessTypeName) {
                    \(raw: allProtocolWitnessProperties)
                
                    \(raw: protocolWitnessInit)
                
                    \(raw: wrappedFunctions)
                
                    \(raw: protocolWitnessStaticVar)
                
                    \(raw: protocolWitnessFunction)
                }
                """
        }
        
        return [witnessDecl]
    }
}


// MARK: - Capturing data

private func makeCapturedProperties(from structDecl: StructDeclSyntax) -> [CapturedProperty] {
    structDecl
        .memberBlock
        .members
        .compactMap { member -> [CapturedProperty]? in
            guard
                let varDecl = member
                    .decl
                    .as(VariableDeclSyntax.self)
            else {
                return nil
            }
            
            
            
            
            
            
            
            let bindings = varDecl
                .bindings
            
            let initializerValue = bindings
                .first?
                .initializer?
                .value
            
            let needsExplicitWrappingProperty =
            initializerValue == nil
            ||
            initializerValue?.is(FunctionCallExprSyntax.self) == true
            
            let isPrivate = varDecl
                .modifiers
                .contains { $0.name.tokenKind == .keyword(.private) } == true
            
            let canBeUsedAsIs = bindings
                .contains { $0.initializer?.equal != nil } == true
            
            let isIncluded = !isPrivate && (needsExplicitWrappingProperty || canBeUsedAsIs)
            
            guard isIncluded else {
                return nil
            }
            
            
            let modifier = varDecl
                .modifiers
                .first {
                    $0.name.tokenKind == .keyword(.internal)
                    || $0.name.tokenKind == .keyword(.public)
                    || $0.name.tokenKind == .keyword(.open)
                }?
                .name
                .trimmedDescription
            
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
                .compactMap { binding -> CapturedProperty? in
                    
                    let accessorBlock = binding.accessorBlock
                    let isComputed = accessorBlock != nil
                    
                    
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
                    
                    
                    
                    
                    
                    
                    
                    let setter = accessorBlock?
                        .accessors
                        .as(AccessorDeclListSyntax.self)?
                        .first { $0.accessorSpecifier.tokenKind == .keyword(.set) }?
                        .trimmedDescription
                    
                    
                    let type = binding.typeAnnotation?.type.trimmedDescription
                    let name = binding.pattern.trimmedDescription
                    let accessor = accessorBlock?.trimmedDescription
                    let equals = binding.initializer?.value.trimmedDescription
                    
                    
                    return CapturedProperty(
                        modifier: modifier,
                        letOrVar: letOrVar,
                        name: name,
                        type: type,
                        accessor: accessor,
                        setter: setter,
                        equals: equals,
                        isAsync: isAsync,
                        isThrowing: isThrowing,
                        isStatic: isStatic,
                        isComputed: isComputed,
                        closureContents: closureContents
                    )
                }
        }
        .flatMap { $0 }
}

private func makeCapturedFunctions(from structDecl: StructDeclSyntax) -> [CapturedFunction] {
    structDecl
        .memberBlock
        .members
        .compactMap { member -> FunctionDeclSyntax? in
            guard
                let function = member.decl.as(FunctionDeclSyntax.self),
                function.modifiers.contains(where: { $0.name.tokenKind == .keyword(.private) }) == false
            else {
                return nil
            }
            
            return function
        }
        .map {
            let modifier = $0
                .modifiers
                .first {
                    $0.name.tokenKind == .keyword(.internal)
                    || $0.name.tokenKind == .keyword(.public)
                    || $0.name.tokenKind == .keyword(.open)
                }?
                .name
                .trimmedDescription
            
            
            let signature = $0.signature
            
            
            let effectSpecifiers = signature.effectSpecifiers
            let isAsync = effectSpecifiers?.asyncSpecifier != nil
            let isThrows = effectSpecifiers?.throwsSpecifier != nil
            
            
            
            struct CapturedClosure {
                let name: String
                let type: String
            }

            let capturedClosure = signature
                .parameterClause
                .parameters
                .compactMap {
                    CapturedClosure(
                        name: $0.firstName.text,
                        type: $0.type.description
                    )
                }
            
            
            
            let parameterTypesList = capturedClosure
                .map { $0.type }
                .joined(separator: ", ")
            
            let parameterNameWithTypeList = capturedClosure
                .map { "\($0.name): \($0.type)" }
                .joined(separator: ", ")
            
            let parameterNameWithNameList = capturedClosure
                .map { "\($0.name)" }
                .joined(separator: ", ")
            
            
            
            
            
            let returnValue = signature
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
            
            
            
            let type = "\(signatureDecl) -> \(returnValueOrVoid)"
            
            
            
            let callsite = """
                func \(name)\(signatureParameterNamesDecl)\(returnValueIfNotVoid) {
                \(tryAwaitOrEmpty)_\(name)(\(parameterNameWithNameList))
                }
                """
            
            
            
            return CapturedFunction(
                modifier: modifier,
                name: name,
                type: type,
                callsite: callsite
            )
        }
}


private func makeProtocolWitnessProperties(from capturedProperty: CapturedProperty) -> String? {
    let type = capturedProperty.type.flatMap({ ": \($0)" })
    
    
    
    
    
    let isMissingType = type == nil
    let isLet = capturedProperty.letOrVar == "let"
    
    if isMissingType, isLet {
        return nil
    }
    
    
    
    
    
    
    let typeOrEmpty = type ?? ""
    let staticOrEmpty = capturedProperty.isStatic ? "static " : ""
    let modifierOrEmpty = capturedProperty.modifier.flatMap { "\($0) " } ?? ""
    let propertyPrefix = "\(staticOrEmpty)\(modifierOrEmpty)var"
    
    let name = capturedProperty.name
    
    
    
    
    let isVar = capturedProperty.letOrVar == "var"
    
    
    
    
    
    
    
    if
        isVar,
        let equals = capturedProperty.equals
    {
        return """
                \(propertyPrefix) \(name)\(typeOrEmpty) = \(equals)
                """
    } else {
        
        let asyncThrows = if capturedProperty.isAsync, capturedProperty.isThrowing {
            " async throws"
        } else if capturedProperty.isAsync {
            " async"
        } else if capturedProperty.isThrowing {
            " throws"
        } else {
            ""
        }
        
        let getExpression = if capturedProperty.isAsync, capturedProperty.isThrowing {
            "try await _\(capturedProperty.name)()"
        } else if capturedProperty.isThrowing {
            "try _\(capturedProperty.name)()"
        } else {
            "_\(capturedProperty.name)"
        }
        
        let getName = "get\(asyncThrows)"
        let getter = "\(getName) { \(getExpression) }"
        
        
        
        let rhs: String
        
        if capturedProperty.isThrowing {
            let typeRhs = capturedProperty.closureContents.flatMap { " = { \($0) }" }
            ?? capturedProperty.equals.flatMap { " = \($0)" }
            ?? ""
            
            rhs = capturedProperty.type.flatMap { ": () throws -> \($0)\(typeRhs)" }
            ?? ""
        } else {
            let defaultValue = capturedProperty.closureContents.flatMap { " = { \($0) }()" }
            ?? capturedProperty.equals.flatMap { " = \($0)" }
            ?? ""
            
            rhs = capturedProperty.type.flatMap { ": \($0)\(defaultValue)" }
            ?? ""
        }
        
        
        
        let underscoredProperty = "\(propertyPrefix) _\(name)\(rhs)"
        
        let setter = capturedProperty.setter.flatMap { "\n\($0)" } ?? ""
        
        let wrappedProperty = """
                \(propertyPrefix) \(name)\(typeOrEmpty) {
                \(getter)\(setter)
                }
                """
        
        
        
        
        return """
                \(wrappedProperty)
                
                \(underscoredProperty)
                """
    }
}

private func makeProtocolWitnessProperties(from capturedFunction: CapturedFunction) -> String {
    let modifierOrEmpty = capturedFunction.modifier.flatMap { "\($0) " } ?? ""
    let propertyPrefix = "\(modifierOrEmpty)var"
    
    let name = capturedFunction.name
    let type = ": \(capturedFunction.type)"
    
    return "\(propertyPrefix) _\(name)\(type)"
}

private func makeProtocolWitnessInitializerParameters(
    from initializerParameters: [InitializerParameter],
    productionName: String
) -> String {
    initializerParameters
        .map { parameter -> String in
            let asyncThrowsOrEmpty = if parameter.isAsync, parameter.isThrowing {
                "try await "
            } else if parameter.isAsync {
                "await "
            } else if parameter.isThrowing {
                "try "
            } else {
                ""
            }
            
            let value = "\(asyncThrowsOrEmpty)\(productionName).\(parameter.name)"
            let closureWrappedValueOrValue = parameter.isThrowing ? "{ \(value) }" : value
            
            return "\(parameter.name):\(closureWrappedValueOrValue)"
        }
        .joined(separator: ",\n")
}


// MARK: - Metadata

private func makeWitnessTypeName(from node: AttributeSyntax) -> String {
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

private func makeProductionInstanceName(from node: AttributeSyntax) -> String {
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

private func declGroupIsMainActor(_ decl: some DeclGroupSyntax) -> Bool {
    decl
        .attributes
        .contains {  $0
            .as(AttributeSyntax.self)?
            .attributeName
            .as(IdentifierTypeSyntax.self)?
            .name
            .tokenKind == .identifier("MainActor")
        } == true
}


// MARK: - Types

private struct CapturedProperty {
    let modifier: String?
    let letOrVar: String
    let name: String
    let type: String?
    let accessor: String?
    let setter: String?
    let equals: String?
    let isAsync: Bool
    let isThrowing: Bool
    let isStatic: Bool
    let isComputed: Bool
    let closureContents: String?
}

private struct CapturedFunction {
    let modifier: String?
    let name: String
    let type: String
    let callsite: String
}

private struct InitializerParameter {
    let modifier: String?
    let letOrVar: String?
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
