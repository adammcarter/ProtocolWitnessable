import SwiftSyntax


func makeCapturedProperties(from decl: some DeclSyntaxProtocol) -> [CapturedProperty] {
    guard 
        let memberBlock =
            decl.as(StructDeclSyntax.self)?.memberBlock
            ?? decl.as(ProtocolDeclSyntax.self)?.memberBlock
    else {
        return []
    }
    
    return makeCapturedProperties(from: memberBlock)
}

func makeCapturedProperties(from memberBlock: MemberBlockSyntax) -> [CapturedProperty] {
    memberBlock
        .members
        .compactMap(makeCapturedProperty)
        .flatMap { $0 }
}

func makeCapturedProperty(from blockListElement: MemberBlockItemListSyntax.Element) -> [CapturedProperty]? {
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
    
    let isLet = varDecl.bindingSpecifier.tokenKind == .keyword(.let)
    
    
    return varDecl
        .bindings
        .compactMap {
            makeCapturedProperty(
                from: $0,
                isLet: isLet,
                isStatic: isStatic,
                isLazy: isLazy
            )
        }
}

func makeCapturedProperty(
    from patternBindingList: PatternBindingListSyntax.Element,
    isLet: Bool,
    isStatic: Bool,
    isLazy: Bool
) -> CapturedProperty? {
    guard
        let type = patternBindingList.typeAnnotation?.type.trimmedDescription
            ?? makeImpliedType(for: patternBindingList)
    else {
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
        isLet: isLet,
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

private func makeImpliedType(for patternBinding: PatternBindingListSyntax.Element) -> String? {
    guard let initializer = patternBinding.initializer else {
        return nil
    }
    
    return "\(type(of: initializer.value))"
}


struct CapturedProperty {
    let isLet: Bool
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
