import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics


@main
struct ProtocolWitnessablePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ProtocolWitnessableMacro.self,
    ]
}


public struct ProtocolWitnessableMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let protocolDecl = declaration.as(ProtocolDeclSyntax.self) else {
            throw ProtocolWitnessableError.notAProtocol
        }
        
        let protocolTypeName = protocolDecl.name.trimmedDescription
        let protocolWitnessStructTypeName = makeProtocolWitnessStructTypeName(for: protocolTypeName)
        
        let modifierOrEmpty = modifierOrEmpty(for: protocolDecl)
        
        let capturedProperties = makeCapturedProperties(from: protocolDecl)
        let capturedFunctions = makeCapturedFunctions(from: protocolDecl)
        
        let nonStaticCapturedProperties = capturedProperties.filter { $0.isStatic == false }
        let nonStaticCapturedFunctions = capturedFunctions.filter { $0.isStatic == false }
        

        
        
        
        
        
        let makeErasedProtocolWitnessFunction: String
        let makingProtocolWitness: String
        
        if nonStaticCapturedProperties.isEmpty && nonStaticCapturedFunctions.isEmpty {
            makeErasedProtocolWitnessFunction = """
                static func makeErasedProtocolWitness() -> \(protocolTypeName) {
                \(protocolWitnessStructTypeName)()
                }
                """
            
            makingProtocolWitness = """
                func makingProtocolWitness() -> \(protocolWitnessStructTypeName) {
                \(protocolWitnessStructTypeName)()
                }
                """
        } else {
            let erasedProtocolWitnessFunctionParameters = makeErasedProtocolWitnessFunctionParameters(
                capturedProperties: nonStaticCapturedProperties,
                capturedFunctions: nonStaticCapturedFunctions
            )
            
            
            
            
            let needsAsyncAwait = nonStaticCapturedProperties.contains(where: \.isAsync)
            let needsTryThrows = nonStaticCapturedProperties.contains(where: \.isThrowing)
            
            let asyncThrowsOrEmpty = if needsAsyncAwait {
                "async "
            } else if needsTryThrows {
                "throws "
            } else {
                ""
            }
            
            let awaitOrEmpty = needsAsyncAwait ? "await " : ""
            
            
            let erasedProtocolWitnessInitializerParameters = makeProtocolWitnessInitializerParameters(
                capturedProperties: nonStaticCapturedProperties,
                capturedFunctions: nonStaticCapturedFunctions,
                supportsAsyncThrows: false
            )
            
            
            makeErasedProtocolWitnessFunction = """
                static func makeErasedProtocolWitness(
                \(erasedProtocolWitnessFunctionParameters)
                ) -> \(protocolTypeName) {
                \(protocolWitnessStructTypeName)(
                \(erasedProtocolWitnessInitializerParameters)
                )
                }
                """
            
            
            let protocolWitnessInitializerParameters = makeProtocolWitnessInitializerParameters(
                capturedProperties: nonStaticCapturedProperties,
                capturedFunctions: nonStaticCapturedFunctions,
                supportsAsyncThrows: true
            )
            
            
            makingProtocolWitness = """
                func makingProtocolWitness() \(asyncThrowsOrEmpty)-> \(protocolWitnessStructTypeName) {
                \(awaitOrEmpty)\(protocolWitnessStructTypeName)(
                \(protocolWitnessInitializerParameters)
                )
                }
                """
        }
        
        let factoryFunctions = """
            \(makeErasedProtocolWitnessFunction)
            
            \(makingProtocolWitness)
            """

        
        
        
        
        
        
        
        
        let protocolWitnessStruct: String
        
        if capturedProperties.isEmpty && capturedFunctions.isEmpty {
            protocolWitnessStruct = """
                \(modifierOrEmpty)struct \(protocolWitnessStructTypeName): \(protocolTypeName) {
                \(factoryFunctions)
                }
                """
        } else {
            let propertiesAsPropertiesAndWrappedProperties = capturedProperties
                .compactMap(makePropertiesAsPropertiesAndWrappedProperties)
                .joined(separator: "\n\n")
            
            
            let functionsAsPropertiesAndWrappedFunctions = capturedFunctions
                .map(makeFunctionsAsPropertiesAndWrappedFunctions)
                .joined(separator: "\n\n")
            
            
            
            let separator = propertiesAsPropertiesAndWrappedProperties.isEmpty
                || functionsAsPropertiesAndWrappedFunctions.isEmpty
                ? ""
                : "\n\n"
            
            let protocolWitnessStructBody = [
                propertiesAsPropertiesAndWrappedProperties,
                functionsAsPropertiesAndWrappedFunctions
            ].joined(separator: separator)

            
            protocolWitnessStruct = """
                \(modifierOrEmpty)struct \(protocolWitnessStructTypeName): \(protocolTypeName) {
                \(protocolWitnessStructBody)
                
                \(factoryFunctions)
                }
                """
        }
        
        
        return [
            DeclSyntax(stringLiteral: protocolWitnessStruct)
        ]
    }
}


// MARK: - Capturing properties

private func makeCapturedProperties(from decl: ProtocolDeclSyntax) -> [CapturedProperty] {
    decl
        .memberBlock
        .members
        .compactMap(makeCapturedProperty)
        .flatMap { $0 }
}

private func makeCapturedProperty(from blockListElement: MemberBlockItemListSyntax.Element) -> [CapturedProperty]? {
    guard
        let varDecl = blockListElement.decl.as(VariableDeclSyntax.self)
    else {
        return nil
    }

    
    let bindings = varDecl.bindings
    let initializerValue = bindings.first?.initializer?.value
    
    let needsExplicitWrappingProperty = initializerValue == nil
        || initializerValue?.is(FunctionCallExprSyntax.self) == true
    
    let canBeUsedAsIs = bindings.contains { $0.initializer?.equal != nil }
    
    guard
        varDecl.isPrivate == false,
        (needsExplicitWrappingProperty || canBeUsedAsIs)
    else {
        return nil
    }
    

    
    let isStatic = varDecl
        .modifiers
        .contains { $0.name.tokenKind == .keyword(.static) }
    
    let isLazy = varDecl
        .modifiers
        .contains { $0.name.tokenKind == .keyword(.lazy) }
    
    
    return varDecl
        .bindings
        .compactMap {
            makeCapturedProperty(from: $0, isStatic: isStatic, isLazy: isLazy)
        }
}

private func makeCapturedProperty(
    from patternBindingList: PatternBindingListSyntax.Element,
    isStatic: Bool,
    isLazy: Bool
) -> CapturedProperty? {
    guard let type = patternBindingList.typeAnnotation?.type.trimmedDescription else {
        return nil
    }
    
    let isFunctionType = patternBindingList.typeAnnotation?.type.is(FunctionTypeSyntax.self) == true
    
    let accessorBlock = patternBindingList.accessorBlock
    
    let declList = accessorBlock?
        .accessors
        .as(AccessorDeclListSyntax.self)
    
    
    let isAsync = declList?
        .compactMap { $0.effectSpecifiers?.asyncSpecifier }
        .isEmpty == false
    
    let isThrowing = declList?
        .compactMap { $0.effectSpecifiers?.throwsSpecifier }
        .isEmpty == false
    
    let isGetOnly = declList?.contains {
        $0.accessorSpecifier.tokenKind == .keyword(.set)
    } == false && declList != nil
    
    
    
    let name = patternBindingList.pattern.trimmedDescription
    
    return CapturedProperty(
        name: name,
        type: type,
        isGetOnly: isGetOnly,
        isAsync: isAsync,
        isThrowing: isThrowing,
        isStatic: isStatic,
        isLazy: isLazy,
        isFunctionType: isFunctionType
    )
}


// MARK: - Capturing functions

private func makeCapturedFunctions(from decl: ProtocolDeclSyntax) -> [CapturedFunction] {
    decl
        .memberBlock
        .members
        .compactMap(makeFunctionDecl)
        .map(makeCapturedFunction)
}

private func makeFunctionDecl(from blockListElement: MemberBlockItemListSyntax.Element) -> FunctionDeclSyntax? {
    guard
        let function = blockListElement.decl.as(FunctionDeclSyntax.self),
        function.isPrivate == false
    else {
        return nil
    }
    
    return function
}

private func makeCapturedFunction(from functionDecl: FunctionDeclSyntax) -> CapturedFunction {
    let name = functionDecl.name.text
    
    let modifier = functionDecl
        .modifiers
        .first {
            $0.name.tokenKind == .keyword(.internal)
            || $0.name.tokenKind == .keyword(.public)
            || $0.name.tokenKind == .keyword(.open)
        }?
        .name
        .trimmedDescription
    
    let signature = functionDecl.signature
    
    let returnValue = signature
        .returnClause?
        .trimmedDescription
    
    let effectSpecifiers = signature.effectSpecifiers
    let isAsync = effectSpecifiers?.asyncSpecifier != nil
    let isThrows = effectSpecifiers?.throwsSpecifier != nil
    
    let isStatic = functionDecl
        .modifiers
        .contains { $0.name.tokenKind == .keyword(.static) } == true
    
    let capturedClosureParameters = signature
        .parameterClause
        .parameters
        .map(makeCapturedClosureParameters)

    
    return CapturedFunction(
        modifier: modifier,
        name: name,
        returnValue: returnValue,
        isAsync: isAsync,
        isThrows: isThrows,
        isStatic: isStatic,
        capturedClosureParameters: capturedClosureParameters
    )
}

private func makeCapturedClosureParameters(for parameter: FunctionParameterSyntax) -> CapturedFunction.CapturedClosureParameter {
    .init(
        firstName: parameter.firstName.trimmedDescription,
        secondName: parameter.secondName?.trimmedDescription,
        type: parameter.type.description
    )
}


// MARK: - Make properties

private func makeProtocolWitnessProperties(from capturedProperty: CapturedProperty) -> String? {
    let type = capturedProperty.type.flatMap({ ": \($0)" })
    let name = capturedProperty.name
    
    
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
    
    
    
    let rhs = if capturedProperty.isThrowing {
        ": () throws -> \(capturedProperty.type)"
    } else {
        ": \(capturedProperty.type)"
    }
    
    
    
    let underscoredProperty = "\(capturedProperty.prefix)var _\(name)\(rhs)"
    
    let wrappedProperty = """
                \(capturedProperty.prefix)var \(name)\(type) {
                \(getter)
                }
                """
    
    
    
    
    return """
                \(wrappedProperty)
                
                \(underscoredProperty)
                """
}

private func makeProtocolWitnessProperties(from capturedFunction: CapturedFunction) -> String {
    "\(capturedFunction.prefix)var _\(capturedFunction.name): \(capturedFunction.type)"
}


// MARK: - Metadata

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


// MARK: - Helpers

private func modifierOrEmpty(for protocolDecl: ProtocolDeclSyntax) -> String {
    let modifierOrNil = protocolDecl
        .modifiers
        .first(where: {
            $0.name.tokenKind == .keyword(.internal)
            || $0.name.tokenKind == .keyword(.public)
            || $0.name.tokenKind == .keyword(.private)
            || $0.name.tokenKind == .keyword(.fileprivate)
        })?
        .name.trimmedDescription
    
    return modifierOrNil.flatMap { "\($0) " } ?? ""
}

private func makeProtocolWitnessStructTypeName(for protocolTypeName: String) -> String {
    "\(protocolTypeName)ProtocolWitness"
}

private func makePropertiesAsPropertiesAndWrappedProperties(for capturedProperty: CapturedProperty) -> String {
     [
        makeWrappedProperty(for: capturedProperty),
        makeProperty(for: capturedProperty),
    ]
        .compactMap { $0 }
        .joined(separator: "\n\n")
}

private func makeWrappedProperty(for capturedProperty: CapturedProperty) -> String? {
    guard capturedProperty.isGetOnly else {
        return nil
    }
    
    guard capturedProperty.isStatic == false else {
        return nil
    }
    
    let getter = if capturedProperty.isAsync {
        "get async { _\(capturedProperty.name) }"
    } else if capturedProperty.isThrowing {
        "get throws { try _\(capturedProperty.name)() }"
    } else {
        "_\(capturedProperty.name)"
    }
    
    return """
        \(capturedProperty.prefix)var \(capturedProperty.name): \(capturedProperty.type) {
        \(getter)
        }
        """
}

private func makeProperty(for capturedProperty: CapturedProperty) -> String? {
    let defaultValueOrEmpty = capturedProperty.isStatic
    ? " = { .init() }()"
    : ""
    
    
    let underscoreOrEmpty = capturedProperty.isGetOnly && capturedProperty.isStatic == false
    ? "_"
    : ""
    
    let prefix = "\(capturedProperty.prefix)var \(underscoreOrEmpty)"
    
    let type = if capturedProperty.isThrowing {
        "() throws -> \(capturedProperty.type)"
    } else {
        "\(capturedProperty.type)\(defaultValueOrEmpty)"
    }
    
    return "\(prefix)\(capturedProperty.name): \(type)"}

private func makeFunctionsAsPropertiesAndWrappedFunctions(for capturedFunction: CapturedFunction) -> String {
    let wrappedFunction = makeWrappedFunction(for: capturedFunction)
    
    
    
    let underscoredClosureParameters = capturedFunction
        .capturedClosureParameters
        .map { _ in "_" }
        .joined(separator: ", ")
        .appending(capturedFunction.capturedClosureParameters.isEmpty ? "" : " in")
    
    
    let defaultValueOrEmpty = capturedFunction.isStatic
        ? " = { \(underscoredClosureParameters) }"
        : ""
    
    
    let functionAsProperty = "\(capturedFunction.prefix)var _\(capturedFunction.name): \(capturedFunction.type)\(defaultValueOrEmpty)"
    
    
    
    return """
        \(wrappedFunction)
        
        \(functionAsProperty)
        """
    
}

private func makeWrappedFunction(for capturedFunction: CapturedFunction) -> String {
    let parameterNamesWithTypes = capturedFunction
        .capturedClosureParameters
        .map {
            let fullName = if let secondName = $0.secondName {
                "\($0.firstName) \(secondName)"
            } else {
                $0.firstName
            }

            return "\(fullName): \($0.type)"
        }
        .joined(separator: ", ")
    
    let parameterNames = capturedFunction
        .capturedClosureParameters
        .map { "\($0.secondName ?? $0.firstName)" }
        .joined(separator: ", ")
    
    
    let signatureParameterNamesDecl = if capturedFunction.isAsync, capturedFunction.isThrows {
        "(\(parameterNamesWithTypes)) async throws"
    } else if capturedFunction.isAsync {
        "(\(parameterNamesWithTypes)) async"
    } else if capturedFunction.isThrows {
        "(\(parameterNamesWithTypes)) throws"
    } else {
        "(\(parameterNamesWithTypes))"
    }
    
    
    let returnValueIfNotVoid = capturedFunction.returnValue ?? ""
    
    
    
    let tryAwaitOrEmpty = if capturedFunction.isAsync, capturedFunction.isThrows {
        "try await "
    } else if capturedFunction.isAsync {
        "await "
    } else if capturedFunction.isThrows {
        "try "
    } else {
        ""
    }
    
    
    let functionCallsite = "\(capturedFunction.name)\(signatureParameterNamesDecl)\(returnValueIfNotVoid)"
    let functionBody = "\(tryAwaitOrEmpty)_\(capturedFunction.name)(\(parameterNames))"
    
    
    return """
        \(capturedFunction.prefix)func \(functionCallsite) {
        \(functionBody)
        }
        """

}

private func makeErasedProtocolWitnessFunctionParameters(
    capturedProperties: [CapturedProperty],
    capturedFunctions: [CapturedFunction]
) -> String {
    let propertyParameters = capturedProperties
        .map {
            let rhs: String
            
            if $0.isThrowing {
                rhs = "@escaping () throws -> \($0.type)"
            } else {
                let escapingOrEmpty = $0.isFunctionType ? "@escaping " : ""
                
                rhs = "\(escapingOrEmpty)\($0.type)"
            }
            
            return "\($0.name): \(rhs)"
        }
    
    
    
    let functionParameters = capturedFunctions
        .map {
            "\($0.name): @escaping \($0.type)"
        }
    
    
    
    return [
        propertyParameters,
        functionParameters,
    ]
        .flatMap { $0 }
        .joined(separator: ",\n")
}

private func makeProtocolWitnessInitializerParameters(
    capturedProperties: [CapturedProperty],
    capturedFunctions: [CapturedFunction],
    supportsAsyncThrows: Bool
) -> String {
    let propertyInitializerParameters = capturedProperties
        .map {
            let rhs = if $0.isThrowing, supportsAsyncThrows {
                "{ try \($0.name) }"
            } else {
                "\($0.name)"
            }

            
            let underscoreOrEmpty = $0.isGetOnly ? "_" : ""
            
            return "\(underscoreOrEmpty)\($0.name): \(rhs)"
        }
    
    
    
    let functionInitializerParameters = capturedFunctions
        .map {
            "_\($0.name): \($0.name)"
        }
    
    
    return [
        propertyInitializerParameters,
        functionInitializerParameters,
    ]
        .flatMap { $0 }
        .joined(separator: ",\n")
}


// MARK: - Types

private struct CapturedProperty {
    let name: String
    let type: String
    let isGetOnly: Bool
    let isAsync: Bool
    let isThrowing: Bool
    let isStatic: Bool
    let isLazy: Bool
    let isFunctionType: Bool
    
    var prefix: String {
        let lazyOrEmpty = isLazy ? "lazy " : ""
        let staticOrEmpty = isStatic ? "static " : ""
        
        return "\(lazyOrEmpty)\(staticOrEmpty)"
    }
}

private struct CapturedFunction {
    let modifier: String?
    let name: String
    let returnValue: String?
    let isAsync: Bool
    let isThrows: Bool
    let isStatic: Bool
    let isLazy = false
    let capturedClosureParameters: [CapturedClosureParameter]
    
    struct CapturedClosureParameter {
        let firstName: String
        let secondName: String?
        let type: String
    }
    
    var prefix: String {
        let lazyOrEmpty = isLazy ? "lazy " : ""
        let modifierOrEmpty = modifier.flatMap { "\($0) " } ?? ""
        let staticOrEmpty = isStatic ? "static " : ""
        
        return "\(lazyOrEmpty)\(modifierOrEmpty)\(staticOrEmpty)"
    }
        
    var type: String {
        let parameterTypesList = capturedClosureParameters
            .map { $0.type }
            .joined(separator: ", ")
        
        
        
        let signatureDecl = if isAsync, isThrows {
            "(\(parameterTypesList)) async throws"
        } else if isAsync {
            "(\(parameterTypesList)) async"
        } else if isThrows {
            "(\(parameterTypesList)) throws"
        } else {
            "(\(parameterTypesList))"
        }
        
        
        
        let returnValueOrVoid = returnValue ?? "-> Void"
        
        
        
        return "\(signatureDecl) \(returnValueOrVoid)"

    }
}

private enum ProtocolWitnessableError: Error, CustomStringConvertible {
    case notAProtocol
    
    var description: String {
        "@ProtocolWitnessable can only be attached to protocols"
    }
}


// MARK: - Extensions

extension FunctionDeclSyntax {
    var isPrivate: Bool { modifiers.isPrivate }
}

extension VariableDeclSyntax {
    var isPrivate: Bool { modifiers.isPrivate }
}

extension DeclModifierListSyntax {
    var isPrivate: Bool {
        contains {
            $0.name.tokenKind == .keyword(.private)
            || $0.name.tokenKind == .keyword(.fileprivate)
        } == true
    }
}