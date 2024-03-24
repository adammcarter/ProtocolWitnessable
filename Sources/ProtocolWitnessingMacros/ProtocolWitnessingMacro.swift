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


public struct WitnessingMacro: PeerMacro, ExtensionMacro {
    /**
     Create the `Witness` inner type
     */
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let protocolDecl = declaration.as(ProtocolDeclSyntax.self) else {
            throw ProtocolWitnessingError.notAProtocol
        }
        
        let protocolTypeName = protocolDecl.name.trimmedDescription
        let protocolWitnessStructTypeName = makeProtocolWitnessStructTypeName(for: protocolTypeName)
        
        let modifierOrEmpty = modifierOrEmpty(for: protocolDecl)
        
        
        
        let capturedProperties = makeCapturedProperties(from: protocolDecl)
        
        let capturedFunctions = makeCapturedFunctions(from: protocolDecl)
        
        
        
        //        public struct MyClientProtocolWitness: MyClient {
        //            public let name: String
        //            public var height: Double
        //
        //            public func doSomething(age: Int) -> Void {
        //                _doSomething(age)
        //            }
        //
        //            var _doSomething: (Int) -> Void
        //        }
        //
        
        
        
        
        
        
        
        let protocolWitnessStruct: String
        
        if capturedProperties.isEmpty && capturedFunctions.isEmpty {
            protocolWitnessStruct = """
                \(modifierOrEmpty)struct \(protocolWitnessStructTypeName): \(protocolTypeName) {
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
                }
                """
        }
        
        
        return [
            DeclSyntax(stringLiteral: protocolWitnessStruct)
        ]
    }
    
    
    
    
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard let protocolDecl = declaration.as(ProtocolDeclSyntax.self) else {
            // This is handled by the peer macro so no need to throw here to avoid duplicate Xcode errors
            return []
        }
        
        
        let protocolTypeName = protocolDecl.name.trimmedDescription
        let protocolWitnessStructTypeName = makeProtocolWitnessStructTypeName(for: protocolTypeName)
        
        let modifierOrEmpty = modifierOrEmpty(for: protocolDecl)
        
        
        
        let capturedProperties = makeCapturedProperties(from: protocolDecl)
            .filter { $0.isStatic == false }
        
        let capturedFunctions = makeCapturedFunctions(from: protocolDecl)
            .filter { $0.isStatic == false }
        
        
        //        public extension MyClient {
        //            static func makeErasedProtocolWitness(
        //                name: String,
        //                height: Double,
        //                doSomething: @escaping (Int) -> Void
        //            ) -> MyClient {
        //                MyClientProtocolWitness(
        //                    name: name,
        //                    height: height,
        //                    _doSomething: doSomething
        //                )
        //            }
        //
        //            func makingProtocolWitness() -> MyClientProtocolWitness {
        //                MyClientProtocolWitness(
        //                    name: name,
        //                    height: height,
        //                    _doSomething: doSomething
        //                )
        //            }
        //        }
        
        
        
        
        let makeErasedProtocolWitnessFunction: String
        let makingProtocolWitness: String
        
        if capturedProperties.isEmpty && capturedFunctions.isEmpty {
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
                capturedProperties: capturedProperties,
                capturedFunctions: capturedFunctions
            )
            
            
            
            
            let needsAsyncAwait = capturedProperties.contains(where: \.isAsync)
            let needsTryThrows = capturedProperties.contains(where: \.isThrowing)
            
            let asyncThrowsOrEmpty = if needsAsyncAwait {
                "async "
            } else if needsTryThrows {
                "throws "
            } else {
                ""
            }
            
            let awaitOrEmpty = needsAsyncAwait ? "await " : ""
            

            let erasedProtocolWitnessInitializerParameters = makeProtocolWitnessInitializerParameters(
                capturedProperties: capturedProperties,
                capturedFunctions: capturedFunctions,
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
                capturedProperties: capturedProperties,
                capturedFunctions: capturedFunctions,
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
        
        let extensionBody = """
            \(modifierOrEmpty)extension \(protocolTypeName) {
            \(makeErasedProtocolWitnessFunction)
            
            \(makingProtocolWitness)
            }
            """
        

        
        
        
        return [
            try ExtensionDeclSyntax("\(raw: extensionBody)")
        ]
    }
}
    
    
    
    
    
    
    
    
    
    
//    public static func expansion(
//        of node: AttributeSyntax,
//        providingMembersOf declaration: some DeclGroupSyntax,
//        in context: some MacroExpansionContext
//    ) throws -> [DeclSyntax] {
//        guard let structDecl = declaration as? StructDeclSyntax else {
//            WitnessingDiagnostic.notAStruct.diagnose(in: declaration, for: context)
//            
//            return []
//        }
//        
//        let protocolWitnessName = makeProductionInstanceName(from: node)
//        let typeName = structDecl.name.text
//        let witnessTypeName = makeWitnessTypeName(from: node)
//
//        
//        
//        let capturedProperties = makeCapturedProperties(from: structDecl)
//        let capturedFunctions = makeCapturedFunctions(from: structDecl)
//        
//        
//        
//        
//        
//        
//        
//        
//        let propertiesForInitializerParameters = capturedProperties.map {
//            InitializerParameter(
//                modifier: $0.modifier,
//                letOrVar: $0.letOrVar,
//                name: $0.name,
//                type: $0.type,
//                equals: $0.equals,
//                isEscaping: false,
//                isAsync: $0.isAsync,
//                isThrowing: $0.isThrowing,
//                isStatic: $0.isStatic,
//                closureContents: $0.closureContents
//            )
//        }
//        
//        
//        let functionsForInitializerParameters = capturedFunctions
//            .filter { $0.isStatic == false }
//            .map {
//                InitializerParameter(
//                    modifier: $0.modifier,
//                    letOrVar: nil,
//                    name: $0.name,
//                    type: $0.type,
//                    equals: nil,
//                    isEscaping: true,
//                    isAsync: false,
//                    isThrowing: false,
//                    isStatic: false,
//                    closureContents: nil
//                )
//            }
//        
//        
//        let allInitializerParameters: [InitializerParameter] = [
//            propertiesForInitializerParameters,
//            functionsForInitializerParameters,
//        ]
//            .flatMap { $0 }
//            .filter { $0.closureContents == nil }
//            .filter { $0.equals == nil }
//
//        
//        
//        let protocolWitnessInit: String
//        
//        if allInitializerParameters.isEmpty {
//            protocolWitnessInit = """
//                init() { }
//                """
//        } else if
//            allInitializerParameters.count == 1,
//            let parameter = allInitializerParameters.first
//        {
//            protocolWitnessInit = """
//                init(\(parameter.name)\(parameter.escapingRhs)) {
//                _\(parameter.name) = \(parameter.name)
//                }
//                """
//        } else {
//            let arguments = allInitializerParameters
//                .map { "\($0.name)\($0.escapingRhs)" }
//                .joined(separator: ",\n")
//            
//            let assigns = allInitializerParameters
//                .map { "_\($0.name) = \($0.name)" }
//                .joined(separator: "\n")
//            
//            protocolWitnessInit = """
//                init(
//                \(arguments)
//                ) {
//                \(assigns)
//                }
//                """
//        }
//        
//        
//        
//        
//        
//        
//        
//        let wrappedFunctions = capturedFunctions
//            .map { "\($0.prefix)\($0.callsite)" }
//            .joined(separator: "\n\n")
//        
//
//        
//        
//        
//        
//        
//        
//        
//        
//        
//        
//        
//        
//        let propertiesFromProtocolWitnessProperties = capturedProperties
//            .compactMap(makeProtocolWitnessProperties)
//            .joined(separator: "\n\n")
//        
//        
//        let propertiesFromProtocolWitnessFunctions = capturedFunctions
//            .map(makeProtocolWitnessProperties)
//            .joined(separator: "\n\n")
//
//        
//        let propertiesSeparator =
//            propertiesFromProtocolWitnessProperties.isEmpty
//            || propertiesFromProtocolWitnessFunctions.isEmpty
//            ? "" : "\n\n"
//        
//        let allProtocolWitnessProperties = [
//            propertiesFromProtocolWitnessProperties,
//            propertiesFromProtocolWitnessFunctions,
//        ]
//            .joined(separator: propertiesSeparator)
//        
//        
//        
//        
//        let nonComputedParameters = capturedProperties
//            .filter { $0.isComputed == false }
//    
//        let expandedParameters = nonComputedParameters
//            .filter { $0.equals == nil }
//            .map {
//                "\($0.name): \($0.type ?? "")"
//            }
//            .joined(separator: ",\n")
//
//        
//        
//        
//        let protocolWitnessFunctions = makeProtocolWitnessFunction(
//            structDecl: structDecl,
//            protocolWitnessName: protocolWitnessName,
//            typeName: typeName,
//            witnessTypeName: witnessTypeName,
//            allInitializerParameters: allInitializerParameters,
//            expandedParameters: expandedParameters,
//            nonComputedParameters: nonComputedParameters
//        )
//        
//        
//        
//        let witnessDecl: DeclSyntax
//        
//        if allProtocolWitnessProperties.isEmpty {
//            witnessDecl = """
//                struct \(raw: witnessTypeName) {
//                    \(raw: protocolWitnessInit)
//                
//                    \(raw: protocolWitnessFunctions)
//                }
//                """
//        } else {
//            witnessDecl = """
//                struct \(raw: witnessTypeName) {
//                    \(raw: allProtocolWitnessProperties)
//                
//                    \(raw: protocolWitnessInit)
//                
//                    \(raw: wrappedFunctions)
//                
//                    \(raw: protocolWitnessFunctions)
//                }
//                """
//        }
//        
//        return [witnessDecl]
//    }
//}




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
                .type
                .as(IdentifierTypeSyntax.self)?
                .name
                .text
            
            
            
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


// MARK: - Protocol witness functions

private func makeProtocolWitnessFunction(
    structDecl: StructDeclSyntax,
    protocolWitnessName: String,
    typeName: String,
    witnessTypeName: String,
    allInitializerParameters: [InitializerParameter],
    expandedParameters: String,
    nonComputedParameters: [CapturedProperty]
) -> String {
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
    
    
    
    
    
    
    
    
    
    
    
    
    let returnProtocolWitnessInitFunctionName = "return \(typeName).\(witnessTypeName)"
    
    
    let protocolWitnessInitializerParameters = makeProtocolWitnessInitializerParameters(
        from: allInitializerParameters,
        productionName: protocolWitnessName
    )
    
    
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
    
    
    
    
    
    return """
        private static var _\(protocolWitnessName): \(typeName)?
        
        \(staticFuncProductionFunctionDeclaration)
        let \(protocolWitnessName) = _\(protocolWitnessName) ?? \(letProductionInit)
        
        if _\(protocolWitnessName) == nil {
        _\(protocolWitnessName) = \(protocolWitnessName)
        }
        
        \(returnProtocolWitnessInitializer)
        }
        """
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
    
    
    let returnValueIfNotVoid = capturedFunction.returnValue.flatMap { " -> \($0)" } ?? ""
    
    
    
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
        
        
        
        let returnValueOrVoid = returnValue ?? "Void"
        
        
        
        return "\(signatureDecl) -> \(returnValueOrVoid)"

    }
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



private enum ProtocolWitnessingError: Error, CustomStringConvertible {
    case notAProtocol
    
    var description: String {
        "@ProtocolWitnessing can only be attached to protocols"
    }
}
