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


// MARK: - Capturing data

private func makeCapturedProperties(from decl: ProtocolDeclSyntax) -> [CapturedProperty] {
    decl
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
                .contains {
                    $0.name.tokenKind == .keyword(.private)
                    || $0.name.tokenKind == .keyword(.fileprivate)
                } == true
            
            let canBeUsedAsIs = bindings
                .contains { $0.initializer?.equal != nil } == true
            
            let isIncluded = !isPrivate && (needsExplicitWrappingProperty || canBeUsedAsIs)
            
            guard isIncluded else {
                return nil
            }
            
            
            
            
                        
            let isStatic = member
                .decl
                .as(VariableDeclSyntax.self)?
                .modifiers
                .contains { $0.name.tokenKind == .keyword(.static) } == true
            
            let isLazy = varDecl
                .modifiers
                .contains { $0.name.tokenKind == .keyword(.lazy) }
        
            
            
            
            
            
            
            return varDecl
                .bindings
                .compactMap { binding -> CapturedProperty? in
                    guard let type = binding.typeAnnotation?.type.trimmedDescription else {
                        return nil
                    }
                    
                    let isFunctionType = binding.typeAnnotation?.type.is(FunctionTypeSyntax.self) == true
                    
                    let accessorBlock = binding.accessorBlock
                    
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
                    
                    
                    
                    
                    
                    let name = binding.pattern.trimmedDescription
                    
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
        }
        .flatMap { $0 }
}

private func makeCapturedFunctions(from decl: ProtocolDeclSyntax) -> [CapturedFunction] {
    decl
        .memberBlock
        .members
        .compactMap { member -> FunctionDeclSyntax? in
            guard
                let function = member.decl.as(FunctionDeclSyntax.self)
            else {
                return nil
            }

            let isPrivate = function
                .modifiers
                .contains {
                    $0.name.tokenKind == .keyword(.private)
                    || $0.name.tokenKind == .keyword(.fileprivate)
                } == true
            
            guard isPrivate == false else {
                return nil
            }
            
            return function
        }
        .map { function -> CapturedFunction in
            let modifier = function
                .modifiers
                .first {
                    $0.name.tokenKind == .keyword(.internal)
                    || $0.name.tokenKind == .keyword(.public)
                    || $0.name.tokenKind == .keyword(.open)
                }?
                .name
                .trimmedDescription
            
            
            let signature = function.signature
            
            
            let effectSpecifiers = signature.effectSpecifiers
            let isAsync = effectSpecifiers?.asyncSpecifier != nil
            let isThrows = effectSpecifiers?.throwsSpecifier != nil
            
            
            
            

            let capturedClosureParameters = signature
                .parameterClause
                .parameters
                .compactMap {
                    CapturedFunction.CapturedClosureParameter(
                        name: $0.firstName.text,
                        type: $0.type.description
                    )
                }
            
            
            
            let returnValue = signature
                .returnClause?
                .trimmedDescription
            
            
            
            let name = function.name.text

            
            let isStatic = function
                .modifiers
                .contains { $0.name.tokenKind == .keyword(.static) } == true

            
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
}


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
    let parameterNameWithTypeList = capturedFunction.capturedClosureParameters
        .map { "\($0.name): \($0.type)" }
        .joined(separator: ", ")
    
    let parameterNameWithNameList = capturedFunction.capturedClosureParameters
        .map { "\($0.name)" }
        .joined(separator: ", ")
    
    
    let signatureParameterNamesDecl = if capturedFunction.isAsync, capturedFunction.isThrows {
        "(\(parameterNameWithTypeList)) async throws"
    } else if capturedFunction.isAsync {
        "(\(parameterNameWithTypeList)) async"
    } else if capturedFunction.isThrows {
        "(\(parameterNameWithTypeList)) throws"
    } else {
        "(\(parameterNameWithTypeList))"
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
    let functionBody = "\(tryAwaitOrEmpty)_\(capturedFunction.name)(\(parameterNameWithNameList))"
    
    
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
        let name: String
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
