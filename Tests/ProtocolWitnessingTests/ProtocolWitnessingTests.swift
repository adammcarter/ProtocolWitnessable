import MacroTesting
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(ProtocolWitnessingMacros)
import ProtocolWitnessingMacros

final class ProtocolWitnessingTests: XCTestCase {
    override func invokeTest() {
//        withMacroTesting(isRecording: true, macros: [
        withMacroTesting(macros: [
            "Witnessing": WitnessingMacro.self,
        ]) {
            super.invokeTest()
        }
    }
}

/*
 TODO: Updates
 - Add fix it for non-struct type to convert type to a struct
 - Use SwiftSyntaxMacros builders?
 - Arg for overriding to not use a singleton and having `production() {}` create a new one each time
    - How does this work with the function passing in params? Weird we pass stuff in then potentially ignore it and return the singleton...
 - Use unique name generator helper for witness type name?
    - Replaces customising Witness type name?
 - Rename @ProtocolWitness
 - Customise `witness()` function name with a new macro argument
 - Enable concurrency checking to "complete" mode - https://forums.swift.org/t/concurrency-checking-in-swift-packages-unsafeflags/61135
 */

// MARK: - Initial sanity checking

extension ProtocolWitnessingTests {
    func testMacro_throwsError_whenAttachedToClass() throws {
        assertMacro {
            """
            @Witnessing
            class MyClientClass {
            }
            """
        } diagnostics: {
            """
            @Witnessing
            ┬──────────
            ├─ 🛑 @Witnessing can only be attached to a struct
            ╰─ 🛑 @Witnessing can only be attached to a struct
            class MyClientClass {
            }
            """
        }
    }
}

// MARK: - Bare minimum

extension ProtocolWitnessingTests {
    func testMacro_addsEmptyInit_whenEmptyStruct() throws {
        assertMacro {
            """
            @Witnessing
            struct MyClient {
            }
            """
        } expansion: {
            """
            struct MyClient {

                struct Witness {
                    init() {

                    }
                }
            }

            extension MyClient {
                private static var _production: MyClient?

                static func production() -> MyClient {
                    let production = _production ?? MyClient()

                    if _production == nil {
                        _production = production
                    }

                    return production
                }

                func witness() -> MyClient.Witness {
                    MyClient.Witness()
                }
            }
            """
        }
    }
}

// MARK: - Functions

// MARK: One

extension ProtocolWitnessingTests {
    func testMacro_addsInitWithVoidToVoidClosure_andPropertyForVoidToVoidClosure_whenOneFunction_andNoArguments_andReturnsVoid() throws {
        assertMacro {
            """
            @Witnessing
            struct MyClient {
                func doSomething() { }
            }
            """
        } expansion: {
            """
            struct MyClient {
                func doSomething() { }

                struct Witness {
                    var _doSomething: () -> Void

                    init(doSomething: @escaping () -> Void) {
                        _doSomething = doSomething
                    }

                    func doSomething() {
                        _doSomething()
                    }
                }
            }

            extension MyClient {
                private static var _production: MyClient?

                static func production() -> MyClient {
                    let production = _production ?? MyClient()

                    if _production == nil {
                        _production = production
                    }

                    return production
                }

                func witness() -> MyClient.Witness {
                    MyClient.Witness(
                        doSomething: doSomething
                    )
                }
            }
            """
        }
    }

    func testMacro_addsInitWithParameterToVoidClosure_andPropertyForParameterToVoidClosure_whenOneFunction_andOneArgument_andReturnsVoid() throws {
        assertMacro {
            """
            @Witnessing
            struct MyClient {
                func doSomething(int: Int) { }
            }
            """
        } expansion: {
            """
            struct MyClient {
                func doSomething(int: Int) { }

                struct Witness {
                    var _doSomething: (Int) -> Void

                    init(doSomething: @escaping (Int) -> Void) {
                        _doSomething = doSomething
                    }

                    func doSomething(int: Int) {
                        _doSomething(int)
                    }
                }
            }

            extension MyClient {
                private static var _production: MyClient?

                static func production() -> MyClient {
                    let production = _production ?? MyClient()

                    if _production == nil {
                        _production = production
                    }

                    return production
                }

                func witness() -> MyClient.Witness {
                    MyClient.Witness(
                        doSomething: doSomething
                    )
                }
            }
            """
        }
    }
    
    func testMacro_addsInitWithParameterToReturnValueClosure_andPropertyForParameterToReturnValueClosure_whenOneFunction_andOneArgument_andReturnValue() throws {
        assertMacro {
            """
            @Witnessing
            struct MyClient {
                func doSomething(int: Int) -> Double { 0.5 }
            }
            """
        } expansion: {
            """
            struct MyClient {
                func doSomething(int: Int) -> Double { 0.5 }

                struct Witness {
                    var _doSomething: (Int) -> Double

                    init(doSomething: @escaping (Int) -> Double) {
                        _doSomething = doSomething
                    }

                    func doSomething(int: Int) -> Double {
                        _doSomething(int)
                    }
                }
            }

            extension MyClient {
                private static var _production: MyClient?

                static func production() -> MyClient {
                    let production = _production ?? MyClient()

                    if _production == nil {
                        _production = production
                    }

                    return production
                }

                func witness() -> MyClient.Witness {
                    MyClient.Witness(
                        doSomething: doSomething
                    )
                }
            }
            """
        }
    }
    
    func testMacro_addsInitWithParametersToReturnValueClosure_andPropertyForParameterToReturnValueClosure_whenOneFunction_andTwoArguments_andReturnValue() throws {
        assertMacro {
            """
            @Witnessing
            struct MyClient {
                func doSomething(int: Int, float: Float) -> Double { 0.5 }
            }
            """
        } expansion: {
            """
            struct MyClient {
                func doSomething(int: Int, float: Float) -> Double { 0.5 }

                struct Witness {
                    var _doSomething: (Int, Float) -> Double

                    init(doSomething: @escaping (Int, Float) -> Double) {
                        _doSomething = doSomething
                    }

                    func doSomething(int: Int, float: Float) -> Double {
                        _doSomething(int, float)
                    }
                }
            }

            extension MyClient {
                private static var _production: MyClient?

                static func production() -> MyClient {
                    let production = _production ?? MyClient()

                    if _production == nil {
                        _production = production
                    }

                    return production
                }

                func witness() -> MyClient.Witness {
                    MyClient.Witness(
                        doSomething: doSomething
                    )
                }
            }
            """
        }
    }
}

// MARK: Two

extension ProtocolWitnessingTests {
    func testMacro_addsInitWithVoidToVoidClosure_andPropertyForVoidToVoidClosure_whenTwoFunctions_andBothHaveNoArguments_andBothReturnsVoid() throws {
        assertMacro {
            """
            @Witnessing
            struct MyClient {
                func doSomething() { }
                func doAnotherThing() { }
            }
            """
        } expansion: {
            """
            struct MyClient {
                func doSomething() { }
                func doAnotherThing() { }

                struct Witness {
                    var _doSomething: () -> Void
                    var _doAnotherThing: () -> Void

                    init(
                        doSomething: @escaping () -> Void,
                        doAnotherThing: @escaping () -> Void
                    ) {
                        _doSomething = doSomething
                        _doAnotherThing = doAnotherThing
                    }

                    func doSomething() {
                        _doSomething()
                    }

                    func doAnotherThing() {
                        _doAnotherThing()
                    }
                }
            }

            extension MyClient {
                private static var _production: MyClient?

                static func production() -> MyClient {
                    let production = _production ?? MyClient()

                    if _production == nil {
                        _production = production
                    }

                    return production
                }

                func witness() -> MyClient.Witness {
                    MyClient.Witness(
                        doSomething: doSomething,
                        doAnotherThing: doAnotherThing
                    )
                }
            }
            """
        }
    }
    
    func testMacro_addsInitWithParameterToVoidClosure_andPropertyForParameterToVoidClosure_whenTwoFunctions_andBothHaveOneArgument_andBothReturnsVoid() throws {
        assertMacro {
            """
            enum MyType {}
            enum OtherType {}
            
            @Witnessing
            struct MyClient {
                func doSomething(arg1: MyType) { }
                func doAnotherThing(otherArg: OtherType) { }
            }
            """
        } expansion: {
            """
            enum MyType {}
            enum OtherType {}
            struct MyClient {
                func doSomething(arg1: MyType) { }
                func doAnotherThing(otherArg: OtherType) { }

                struct Witness {
                    var _doSomething: (MyType) -> Void
                    var _doAnotherThing: (OtherType) -> Void

                    init(
                        doSomething: @escaping (MyType) -> Void,
                        doAnotherThing: @escaping (OtherType) -> Void
                    ) {
                        _doSomething = doSomething
                        _doAnotherThing = doAnotherThing
                    }

                    func doSomething(arg1: MyType) {
                        _doSomething(arg1)
                    }

                    func doAnotherThing(otherArg: OtherType) {
                        _doAnotherThing(otherArg)
                    }
                }
            }

            extension MyClient {
                private static var _production: MyClient?

                static func production() -> MyClient {
                    let production = _production ?? MyClient()

                    if _production == nil {
                        _production = production
                    }

                    return production
                }

                func witness() -> MyClient.Witness {
                    MyClient.Witness(
                        doSomething: doSomething,
                        doAnotherThing: doAnotherThing
                    )
                }
            }
            """
        }
    }
    
    func testMacro_addsInitWithParameterToReturnValueClosure_andPropertyForParameterToReturnValueClosure_whenTwoFunctions_andBothHaveOneArgument_andBothReturnValues() throws {
        assertMacro {
            """
            enum MyType {}
            enum OtherType {}
            
            @Witnessing
            struct MyClient {
                func doSomething(arg1: MyType) -> OtherType { }
                func doAnotherThing(otherArg: OtherType) -> MyType { }
            }
            """
        } expansion: {
            """
            enum MyType {}
            enum OtherType {}
            struct MyClient {
                func doSomething(arg1: MyType) -> OtherType { }
                func doAnotherThing(otherArg: OtherType) -> MyType { }

                struct Witness {
                    var _doSomething: (MyType) -> OtherType
                    var _doAnotherThing: (OtherType) -> MyType

                    init(
                        doSomething: @escaping (MyType) -> OtherType,
                        doAnotherThing: @escaping (OtherType) -> MyType
                    ) {
                        _doSomething = doSomething
                        _doAnotherThing = doAnotherThing
                    }

                    func doSomething(arg1: MyType) -> OtherType {
                        _doSomething(arg1)
                    }

                    func doAnotherThing(otherArg: OtherType) -> MyType {
                        _doAnotherThing(otherArg)
                    }
                }
            }

            extension MyClient {
                private static var _production: MyClient?

                static func production() -> MyClient {
                    let production = _production ?? MyClient()

                    if _production == nil {
                        _production = production
                    }

                    return production
                }

                func witness() -> MyClient.Witness {
                    MyClient.Witness(
                        doSomething: doSomething,
                        doAnotherThing: doAnotherThing
                    )
                }
            }
            """
        }
    }
    
    func testMacro_addsInitWithParametersToReturnValueClosure_andPropertyForParameterToReturnValueClosure_whenTwoFunctions_andBothHaveTwoArguments_andBothReturnValues() throws {
        assertMacro {
            """
            enum MyType {}
            enum OtherType {}
            enum TypeTwo {}
            enum AnotherType {}
            
            @Witnessing
            struct MyClient {
                func doSomething(arg1: MyType, arg2: TypeTwo) -> OtherType { }
                func doAnotherThing(otherArg: OtherType, anotherArg: AnotherType) -> MyType { }
            }
            """
        } expansion: {
            """
            enum MyType {}
            enum OtherType {}
            enum TypeTwo {}
            enum AnotherType {}
            struct MyClient {
                func doSomething(arg1: MyType, arg2: TypeTwo) -> OtherType { }
                func doAnotherThing(otherArg: OtherType, anotherArg: AnotherType) -> MyType { }

                struct Witness {
                    var _doSomething: (MyType, TypeTwo) -> OtherType
                    var _doAnotherThing: (OtherType, AnotherType) -> MyType

                    init(
                        doSomething: @escaping (MyType, TypeTwo) -> OtherType,
                        doAnotherThing: @escaping (OtherType, AnotherType) -> MyType
                    ) {
                        _doSomething = doSomething
                        _doAnotherThing = doAnotherThing
                    }

                    func doSomething(arg1: MyType, arg2: TypeTwo) -> OtherType {
                        _doSomething(arg1, arg2)
                    }

                    func doAnotherThing(otherArg: OtherType, anotherArg: AnotherType) -> MyType {
                        _doAnotherThing(otherArg, anotherArg)
                    }
                }
            }

            extension MyClient {
                private static var _production: MyClient?

                static func production() -> MyClient {
                    let production = _production ?? MyClient()

                    if _production == nil {
                        _production = production
                    }

                    return production
                }

                func witness() -> MyClient.Witness {
                    MyClient.Witness(
                        doSomething: doSomething,
                        doAnotherThing: doAnotherThing
                    )
                }
            }
            """
        }
    }
}

// MARK: Async/await

extension ProtocolWitnessingTests {
    func testMacro_whenOneFunction_andFunctionIsAsync() throws {
        assertMacro {
            """
            @Witnessing
            struct MyClient {
                func doSomething() async { }
            }
            """
        } expansion: {
            """
            struct MyClient {
                func doSomething() async { }

                struct Witness {
                    var _doSomething: () async -> Void

                    init(doSomething: @escaping () async -> Void) {
                        _doSomething = doSomething
                    }

                    func doSomething() async {
                        await _doSomething()
                    }
                }
            }

            extension MyClient {
                private static var _production: MyClient?

                static func production() -> MyClient {
                    let production = _production ?? MyClient()

                    if _production == nil {
                        _production = production
                    }

                    return production
                }

                func witness() -> MyClient.Witness {
                    MyClient.Witness(
                        doSomething: doSomething
                    )
                }
            }
            """
        }
    }
    
    func testMacro_whenTwoFunctions_andBothFunctionsAreAsync() throws {
        assertMacro {
            """
            @Witnessing
            struct MyClient {
                func doSomething() async { }
            
                func doAnotherThing() async { }
            }
            """
        } expansion: {
            """
            struct MyClient {
                func doSomething() async { }

                func doAnotherThing() async { }

                struct Witness {
                    var _doSomething: () async -> Void
                    var _doAnotherThing: () async -> Void

                    init(
                        doSomething: @escaping () async -> Void,
                        doAnotherThing: @escaping () async -> Void
                    ) {
                        _doSomething = doSomething
                        _doAnotherThing = doAnotherThing
                    }

                    func doSomething() async {
                        await _doSomething()
                    }

                    func doAnotherThing() async {
                        await _doAnotherThing()
                    }
                }
            }

            extension MyClient {
                private static var _production: MyClient?

                static func production() -> MyClient {
                    let production = _production ?? MyClient()

                    if _production == nil {
                        _production = production
                    }

                    return production
                }

                func witness() -> MyClient.Witness {
                    MyClient.Witness(
                        doSomething: doSomething,
                        doAnotherThing: doAnotherThing
                    )
                }
            }
            """
        }
    }
    
    func testMacro_whenTwoFunctions_andOnlyOneFunctionsIsAsync() throws {
        assertMacro {
            """
            @Witnessing
            struct MyClient {
                func doSomething() { }
            
                func doAnotherThing() async { }
            }
            """
        } expansion: {
            """
            struct MyClient {
                func doSomething() { }

                func doAnotherThing() async { }

                struct Witness {
                    var _doSomething: () -> Void
                    var _doAnotherThing: () async -> Void

                    init(
                        doSomething: @escaping () -> Void,
                        doAnotherThing: @escaping () async -> Void
                    ) {
                        _doSomething = doSomething
                        _doAnotherThing = doAnotherThing
                    }

                    func doSomething() {
                        _doSomething()
                    }

                    func doAnotherThing() async {
                        await _doAnotherThing()
                    }
                }
            }

            extension MyClient {
                private static var _production: MyClient?

                static func production() -> MyClient {
                    let production = _production ?? MyClient()

                    if _production == nil {
                        _production = production
                    }

                    return production
                }

                func witness() -> MyClient.Witness {
                    MyClient.Witness(
                        doSomething: doSomething,
                        doAnotherThing: doAnotherThing
                    )
                }
            }
            """
        }
    }
}

// MARK: Throwing

extension ProtocolWitnessingTests {
    func testMacro_whenOneFunction_andFunctionIsThrowing() throws {
        assertMacro {
            """
            @Witnessing
            struct MyClient {
                func doSomething() throws { }
            }
            """
        } expansion: {
            """
            struct MyClient {
                func doSomething() throws { }

                struct Witness {
                    var _doSomething: () throws -> Void

                    init(doSomething: @escaping () throws -> Void) {
                        _doSomething = doSomething
                    }

                    func doSomething() throws {
                        try _doSomething()
                    }
                }
            }

            extension MyClient {
                private static var _production: MyClient?

                static func production() -> MyClient {
                    let production = _production ?? MyClient()

                    if _production == nil {
                        _production = production
                    }

                    return production
                }

                func witness() -> MyClient.Witness {
                    MyClient.Witness(
                        doSomething: doSomething
                    )
                }
            }
            """
        }
    }
    
    func testMacro_whenTwoFunctions_andBothFunctionsAreThrowing() throws {
        assertMacro {
            """
            @Witnessing
            struct MyClient {
                func doSomething() throws { }
            
                func doSomethingElse() throws { }
            }
            """
        } expansion: {
            """
            struct MyClient {
                func doSomething() throws { }

                func doSomethingElse() throws { }

                struct Witness {
                    var _doSomething: () throws -> Void
                    var _doSomethingElse: () throws -> Void

                    init(
                        doSomething: @escaping () throws -> Void,
                        doSomethingElse: @escaping () throws -> Void
                    ) {
                        _doSomething = doSomething
                        _doSomethingElse = doSomethingElse
                    }

                    func doSomething() throws {
                        try _doSomething()
                    }

                    func doSomethingElse() throws {
                        try _doSomethingElse()
                    }
                }
            }

            extension MyClient {
                private static var _production: MyClient?

                static func production() -> MyClient {
                    let production = _production ?? MyClient()

                    if _production == nil {
                        _production = production
                    }

                    return production
                }

                func witness() -> MyClient.Witness {
                    MyClient.Witness(
                        doSomething: doSomething,
                        doSomethingElse: doSomethingElse
                    )
                }
            }
            """
        }
    }
    
    func testMacro_whenTwoFunctions_andOneFunctionIsThrowing_andOtherFunctionIsNot() throws {
        assertMacro {
            """
            @Witnessing
            struct MyClient {
                func doSomething() { }
            
                func doSomethingElse() throws { }
            }
            """
        } expansion: {
            """
            struct MyClient {
                func doSomething() { }

                func doSomethingElse() throws { }

                struct Witness {
                    var _doSomething: () -> Void
                    var _doSomethingElse: () throws -> Void

                    init(
                        doSomething: @escaping () -> Void,
                        doSomethingElse: @escaping () throws -> Void
                    ) {
                        _doSomething = doSomething
                        _doSomethingElse = doSomethingElse
                    }

                    func doSomething() {
                        _doSomething()
                    }

                    func doSomethingElse() throws {
                        try _doSomethingElse()
                    }
                }
            }

            extension MyClient {
                private static var _production: MyClient?

                static func production() -> MyClient {
                    let production = _production ?? MyClient()

                    if _production == nil {
                        _production = production
                    }

                    return production
                }

                func witness() -> MyClient.Witness {
                    MyClient.Witness(
                        doSomething: doSomething,
                        doSomethingElse: doSomethingElse
                    )
                }
            }
            """
        }
    }
}

// MARK: Complex

extension ProtocolWitnessingTests {
    func testMacro_expandsType_whenFunctionParametersContainsVoidToVoidClosure() throws {
        assertMacro {
            """
            @Witnessing
            struct MyClient {
                func doSomething(completionHandler: (Int) -> Void) {
                    // Complex logic here...
                    completionHandler()
                }
            }
            """
        } expansion: {
            """
            struct MyClient {
                func doSomething(completionHandler: (Int) -> Void) {
                    // Complex logic here...
                    completionHandler()
                }

                struct Witness {
                    var _doSomething: ((Int) -> Void) -> Void

                    init(doSomething: @escaping ((Int) -> Void) -> Void) {
                        _doSomething = doSomething
                    }

                    func doSomething(completionHandler: (Int) -> Void) {
                        _doSomething(completionHandler)
                    }
                }
            }

            extension MyClient {
                private static var _production: MyClient?

                static func production() -> MyClient {
                    let production = _production ?? MyClient()

                    if _production == nil {
                        _production = production
                    }

                    return production
                }

                func witness() -> MyClient.Witness {
                    MyClient.Witness(
                        doSomething: doSomething
                    )
                }
            }
            """
        }
    }
    
    func testMacro_expandsType_whenFunctionParametersContainsParamToVoidClosure() throws {
        assertMacro {
            """
            @Witnessing
            struct MyClient {
                func doSomething(completionHandler: (Int) -> Void) {
                    // Complex logic here...
                    completionHandler(1234567890)
                }
            }
            """
        } expansion: {
            """
            struct MyClient {
                func doSomething(completionHandler: (Int) -> Void) {
                    // Complex logic here...
                    completionHandler(1234567890)
                }

                struct Witness {
                    var _doSomething: ((Int) -> Void) -> Void

                    init(doSomething: @escaping ((Int) -> Void) -> Void) {
                        _doSomething = doSomething
                    }

                    func doSomething(completionHandler: (Int) -> Void) {
                        _doSomething(completionHandler)
                    }
                }
            }

            extension MyClient {
                private static var _production: MyClient?

                static func production() -> MyClient {
                    let production = _production ?? MyClient()

                    if _production == nil {
                        _production = production
                    }

                    return production
                }

                func witness() -> MyClient.Witness {
                    MyClient.Witness(
                        doSomething: doSomething
                    )
                }
            }
            """
        }
    }
    
    func testMacro_expandsType_whenFunctionParametersContainsVoidToVoidClosure_andClosureIsEscaping() throws {
        assertMacro {
            """
            @Witnessing
            struct MyClient {
                func doSomething(completionHandler: @escaping () -> Void) {
                    completionHandler()
                }
            }
            """
        } expansion: {
            """
            struct MyClient {
                func doSomething(completionHandler: @escaping () -> Void) {
                    completionHandler()
                }

                struct Witness {
                    var _doSomething: (@escaping () -> Void) -> Void

                    init(doSomething: @escaping (@escaping () -> Void) -> Void) {
                        _doSomething = doSomething
                    }

                    func doSomething(completionHandler: @escaping () -> Void) {
                        _doSomething(completionHandler)
                    }
                }
            }

            extension MyClient {
                private static var _production: MyClient?

                static func production() -> MyClient {
                    let production = _production ?? MyClient()

                    if _production == nil {
                        _production = production
                    }

                    return production
                }

                func witness() -> MyClient.Witness {
                    MyClient.Witness(
                        doSomething: doSomething
                    )
                }
            }
            """
        }
    }
    
    func testMacro_expandsType_whenFunctionParametersContainsParamToVoidClosure_andClosureIsEscaping() throws {
        assertMacro {
            """
            @Witnessing
            struct MyClient {
                func doSomething(completionHandler: @escaping (Int) -> Void) { }
            }
            """
        } expansion: {
            """
            struct MyClient {
                func doSomething(completionHandler: @escaping (Int) -> Void) { }

                struct Witness {
                    var _doSomething: (@escaping (Int) -> Void) -> Void

                    init(doSomething: @escaping (@escaping (Int) -> Void) -> Void) {
                        _doSomething = doSomething
                    }

                    func doSomething(completionHandler: @escaping (Int) -> Void) {
                        _doSomething(completionHandler)
                    }
                }
            }

            extension MyClient {
                private static var _production: MyClient?

                static func production() -> MyClient {
                    let production = _production ?? MyClient()

                    if _production == nil {
                        _production = production
                    }

                    return production
                }

                func witness() -> MyClient.Witness {
                    MyClient.Witness(
                        doSomething: doSomething
                    )
                }
            }
            """
        }
    }
}

// MARK: Formatting

extension ProtocolWitnessingTests {
    func testMacro_expandsType_whenContainingFunction_andFunctionHasExplicitVoidReturn() throws {
        assertMacro {
            """
            @Witnessing
            struct MyClient {
                func doSomething() -> Void { }
            }
            """
        } expansion: {
            """
            struct MyClient {
                func doSomething() -> Void { }

                struct Witness {
                    var _doSomething: () -> Void

                    init(doSomething: @escaping () -> Void) {
                        _doSomething = doSomething
                    }

                    func doSomething() -> Void {
                        _doSomething()
                    }
                }
            }

            extension MyClient {
                private static var _production: MyClient?

                static func production() -> MyClient {
                    let production = _production ?? MyClient()

                    if _production == nil {
                        _production = production
                    }

                    return production
                }

                func witness() -> MyClient.Witness {
                    MyClient.Witness(
                        doSomething: doSomething
                    )
                }
            }
            """
        }
    }
    
    func testMacro_expandsType_whenContainingFunction_andFunctionHasExtraWhitespaceAroundReturnArrow() throws {
        assertMacro {
            """
            @Witnessing
            struct MyClient {
                func doSomething()   ->   Void { }
            }
            """
        } expansion: {
            """
            struct MyClient {
                func doSomething()   ->   Void { }

                struct Witness {
                    var _doSomething: () -> Void

                    init(doSomething: @escaping () -> Void) {
                        _doSomething = doSomething
                    }

                    func doSomething() -> Void {
                        _doSomething()
                    }
                }
            }

            extension MyClient {
                private static var _production: MyClient?

                static func production() -> MyClient {
                    let production = _production ?? MyClient()

                    if _production == nil {
                        _production = production
                    }

                    return production
                }

                func witness() -> MyClient.Witness {
                    MyClient.Witness(
                        doSomething: doSomething
                    )
                }
            }
            """
        }
    }
    
    func testMacro_expandsType_whenContainingFunction_andFunctionHasExtraWhitespaceAroundFunctionName() throws {
        assertMacro {
            """
            @Witnessing
            struct MyClient {
                func    doSomething()    {    }
            }
            """
        } expansion: {
            """
            struct MyClient {
                func    doSomething()    {    }

                struct Witness {
                    var _doSomething: () -> Void

                    init(doSomething: @escaping () -> Void) {
                        _doSomething = doSomething
                    }

                    func doSomething() {
                        _doSomething()
                    }
                }
            }

            extension MyClient {
                private static var _production: MyClient?

                static func production() -> MyClient {
                    let production = _production ?? MyClient()

                    if _production == nil {
                        _production = production
                    }

                    return production
                }

                func witness() -> MyClient.Witness {
                    MyClient.Witness(
                        doSomething: doSomething
                    )
                }
            }
            """
        }
    }
    
    func testMacro_expandsType_whenContainingFunction_andFunctionHasExtraNewlinesAroundFunctionBody() throws {
        assertMacro {
            """
            @Witnessing
            struct MyClient {
                func doSomething()
                { 
                    /*some logic here*/
                }
            }
            """
        } expansion: {
            """
            struct MyClient {
                func doSomething()
                { 
                    /*some logic here*/
                }

                struct Witness {
                    var _doSomething: () -> Void

                    init(doSomething: @escaping () -> Void) {
                        _doSomething = doSomething
                    }

                    func doSomething() {
                        _doSomething()
                    }
                }
            }

            extension MyClient {
                private static var _production: MyClient?

                static func production() -> MyClient {
                    let production = _production ?? MyClient()

                    if _production == nil {
                        _production = production
                    }

                    return production
                }

                func witness() -> MyClient.Witness {
                    MyClient.Witness(
                        doSomething: doSomething
                    )
                }
            }
            """
        }
    }
    
    func testMacro_expandsType_whenContainingFunction_andFunctionHasExtraNewlinesAndWhitespaceEverywhere() throws {
        assertMacro {
            """
            @Witnessing
            struct MyClient {
                func    doSomething ()
                
                {
                    
                    /*some logic here*/
                    
                }
            }
            """
        } expansion: {
            """
            struct MyClient {
                func    doSomething ()
                
                {
                    
                    /*some logic here*/
                    
                }

                struct Witness {
                    var _doSomething: () -> Void

                    init(doSomething: @escaping () -> Void) {
                        _doSomething = doSomething
                    }

                    func doSomething() {
                        _doSomething()
                    }
                }
            }

            extension MyClient {
                private static var _production: MyClient?

                static func production() -> MyClient {
                    let production = _production ?? MyClient()

                    if _production == nil {
                        _production = production
                    }

                    return production
                }

                func witness() -> MyClient.Witness {
                    MyClient.Witness(
                        doSomething: doSomething
                    )
                }
            }
            """
        }
    }
}

// MARK: - Properties

// MARK: Only properties

extension ProtocolWitnessingTests {
    func testMacro_createsInitWithProperty_whenStructHasOneSimpleLetProperty_andNoFunctions() throws {
        assertMacro {
            """
            @Witnessing
            struct MyClient {
                let someLetProperty: Int
            }
            """
        } expansion: {
            """
            struct MyClient {
                let someLetProperty: Int

                struct Witness {
                    var _someLetProperty: Int

                    var someLetProperty: Int {
                        get {
                            _someLetProperty
                        }
                    }

                    init(someLetProperty: Int) {
                        _someLetProperty = someLetProperty
                    }


                }
            }

            extension MyClient {
                private static var _production: MyClient?

                static func production(
                    someLetProperty: Int
                ) -> MyClient {
                    let production = _production ?? MyClient(
                        someLetProperty: someLetProperty
                    )

                    if _production == nil {
                        _production = production
                    }

                    return production
                }

                func witness() -> MyClient.Witness {
                    MyClient.Witness(
                        someLetProperty: someLetProperty
                    )
                }
            }
            """
        }
    }
    
    func testMacro_createsInitWithProperty_whenStructHasOneSimpleVarProperty_andNoFunctions_andVarHasNoDefaultValue() throws {
        assertMacro {
            """
            @Witnessing
            struct MyClient {
                var someLetProperty: Int
            }
            """
        } expansion: {
            """
            struct MyClient {
                var someLetProperty: Int

                struct Witness {
                    var _someLetProperty: Int

                    init(someLetProperty: Int) {
                        _someLetProperty = someLetProperty
                    }


                }
            }

            extension MyClient {
                private static var _production: MyClient?

                static func production(
                    someLetProperty: Int
                ) -> MyClient {
                    let production = _production ?? MyClient(
                        someLetProperty: someLetProperty
                    )

                    if _production == nil {
                        _production = production
                    }

                    return production
                }

                func witness() -> MyClient.Witness {
                    MyClient.Witness(
                        someLetProperty: someLetProperty
                    )
                }
            }
            """
        }
    }
    
    func testMacro_createsInitWithProperty_whenStructHasOneSimpleLetProperty_andNoFunctions_andLetHasDefaultValue() throws {
        assertMacro {
            """
            @Witnessing
            struct MyClient {
                let someLetProperty = 10
            }
            """
        } expansion: {
            """
            struct MyClient {
                let someLetProperty = 10

                struct Witness {
                    init() {

                    }
                }
            }

            extension MyClient {
                private static var _production: MyClient?

                static func production() -> MyClient {
                    let production = _production ?? MyClient()

                    if _production == nil {
                        _production = production
                    }

                    return production
                }

                func witness() -> MyClient.Witness {
                    MyClient.Witness()
                }
            }
            """
        }
    }
    
    func testMacro_createsInitWithProperty_whenStructHasOneSimpleLetProperty_andNoFunctions_andVarHasDefaultValue() throws {
        assertMacro {
            """
            @Witnessing
            struct MyClient {
                var someLetProperty = 10
            }
            """
        } expansion: {
            """
            struct MyClient {
                var someLetProperty = 10

                struct Witness {
                    init() {

                    }
                }
            }

            extension MyClient {
                private static var _production: MyClient?

                static func production() -> MyClient {
                    let production = _production ?? MyClient()

                    if _production == nil {
                        _production = production
                    }

                    return production
                }

                func witness() -> MyClient.Witness {
                    MyClient.Witness()
                }
            }
            """
        }
    }
}

// MARK: With functions

extension ProtocolWitnessingTests {
    func testMacro_createsInitWithProperty_whenStructHasOneSimpleLetProperty_andOneFunction() throws {
        assertMacro {
            """
            @Witnessing
            struct MyClient {
                let someLetProperty: Int
            
                func doSomething() { }
            }
            """
        } expansion: {
            """
            struct MyClient {
                let someLetProperty: Int

                func doSomething() { }

                struct Witness {
                    var _someLetProperty: Int
                    var _doSomething: () -> Void

                    var someLetProperty: Int {
                        get {
                            _someLetProperty
                        }
                    }

                    init(
                        someLetProperty: Int,
                        doSomething: @escaping () -> Void
                    ) {
                        _someLetProperty = someLetProperty
                        _doSomething = doSomething
                    }

                    func doSomething() {
                        _doSomething()
                    }
                }
            }

            extension MyClient {
                private static var _production: MyClient?

                static func production(
                    someLetProperty: Int
                ) -> MyClient {
                    let production = _production ?? MyClient(
                        someLetProperty: someLetProperty
                    )

                    if _production == nil {
                        _production = production
                    }

                    return production
                }

                func witness() -> MyClient.Witness {
                    MyClient.Witness(
                        someLetProperty: someLetProperty,
                        doSomething: doSomething
                    )
                }
            }
            """
        }
    }
    
    func testMacro_createsInitWithProperty_whenStructHasOneSimpleVarProperty_andOneFunction_andVarHasNoDefaultValue() throws {
        assertMacro {
            """
            @Witnessing
            struct MyClient {
                var someLetProperty: Int
            
                func doSomething() { }
            }
            """
        } expansion: {
            """
            struct MyClient {
                var someLetProperty: Int

                func doSomething() { }

                struct Witness {
                    var _someLetProperty: Int
                    var _doSomething: () -> Void

                    init(
                        someLetProperty: Int,
                        doSomething: @escaping () -> Void
                    ) {
                        _someLetProperty = someLetProperty
                        _doSomething = doSomething
                    }

                    func doSomething() {
                        _doSomething()
                    }
                }
            }

            extension MyClient {
                private static var _production: MyClient?

                static func production(
                    someLetProperty: Int
                ) -> MyClient {
                    let production = _production ?? MyClient(
                        someLetProperty: someLetProperty
                    )

                    if _production == nil {
                        _production = production
                    }

                    return production
                }

                func witness() -> MyClient.Witness {
                    MyClient.Witness(
                        someLetProperty: someLetProperty,
                        doSomething: doSomething
                    )
                }
            }
            """
        }
    }
    
    func testMacro_createsInitWithProperty_whenStructHasOneSimpleLetProperty_andOneFunction_andLetHasDefaultValue() throws {
        assertMacro {
            """
            @Witnessing
            struct MyClient {
                let someLetProperty = 532
            
                func doSomething() { }
            }
            """
        } expansion: {
            """
            struct MyClient {
                let someLetProperty = 532

                func doSomething() { }

                struct Witness {
                    var _doSomething: () -> Void

                    init(doSomething: @escaping () -> Void) {
                        _doSomething = doSomething
                    }

                    func doSomething() {
                        _doSomething()
                    }
                }
            }

            extension MyClient {
                private static var _production: MyClient?

                static func production() -> MyClient {
                    let production = _production ?? MyClient()

                    if _production == nil {
                        _production = production
                    }

                    return production
                }

                func witness() -> MyClient.Witness {
                    MyClient.Witness(
                        doSomething: doSomething
                    )
                }
            }
            """
        }
    }
    
    func testMacro_createsInitWithProperty_whenStructHasOneSimpleLetProperty_andOneFunction_andVarHasDefaultValue() throws {
        assertMacro {
            """
            @Witnessing
            struct MyClient {
                var someLetProperty = 10
            
                func doSomething() { }
            }
            """
        } expansion: {
            """
            struct MyClient {
                var someLetProperty = 10

                func doSomething() { }

                struct Witness {
                    var _doSomething: () -> Void

                    init(doSomething: @escaping () -> Void) {
                        _doSomething = doSomething
                    }

                    func doSomething() {
                        _doSomething()
                    }
                }
            }

            extension MyClient {
                private static var _production: MyClient?

                static func production() -> MyClient {
                    let production = _production ?? MyClient()

                    if _production == nil {
                        _production = production
                    }

                    return production
                }

                func witness() -> MyClient.Witness {
                    MyClient.Witness(
                        doSomething: doSomething
                    )
                }
            }
            """
        }
    }
}

// MARK: Getter

extension ProtocolWitnessingTests {
    func testMacro_addsGetterToWitness_whenPropertyHasGetter_andGetterSpansOneLineOnly() throws {
        assertMacro {
            """
            @Witnessing
            struct MyClient {
                var isThing: Bool { true }
            }
            """
        } expansion: {
            """
            struct MyClient {
                var isThing: Bool { true }

                struct Witness {
                    var _isThing: Bool

                    var isThing: Bool {
                        get {
                            _isThing
                        }
                    }

                    init(isThing: Bool) {
                        _isThing = isThing
                    }


                }
            }

            extension MyClient {
                private static var _production: MyClient?

                static func production() -> MyClient {
                    let production = _production ?? MyClient()

                    if _production == nil {
                        _production = production
                    }

                    return production
                }

                func witness() -> MyClient.Witness {
                    MyClient.Witness(
                        isThing: isThing
                    )
                }
            }
            """
        }
    }
    
    func testMacro_addsGetterToWitness_whenPropertyHasGetter_andGetterSpansMultipleLines() throws {
        assertMacro {
            """
            @Witnessing
            struct MyClient {
                var isThing: Bool {
                    true
                }
            }
            """
        } expansion: {
            """
            struct MyClient {
                var isThing: Bool {
                    true
                }

                struct Witness {
                    var _isThing: Bool

                    var isThing: Bool {
                        get {
                            _isThing
                        }
                    }

                    init(isThing: Bool) {
                        _isThing = isThing
                    }


                }
            }

            extension MyClient {
                private static var _production: MyClient?

                static func production() -> MyClient {
                    let production = _production ?? MyClient()

                    if _production == nil {
                        _production = production
                    }

                    return production
                }

                func witness() -> MyClient.Witness {
                    MyClient.Witness(
                        isThing: isThing
                    )
                }
            }
            """
        }
    }
    
    func testMacro_addsGetterToWitness_whenPropertyHasGetter_andGetterContainsComplexCode() throws {
        assertMacro {
            """
            @Witnessing
            struct MyClient {
                var isThing: Bool {
                    let myThing = true
            
                    print(myThing)
            
                    return myThing
                }
            }
            """
        } expansion: {
            """
            struct MyClient {
                var isThing: Bool {
                    let myThing = true

                    print(myThing)

                    return myThing
                }

                struct Witness {
                    var _isThing: Bool

                    var isThing: Bool {
                        get {
                            _isThing
                        }
                    }

                    init(isThing: Bool) {
                        _isThing = isThing
                    }


                }
            }

            extension MyClient {
                private static var _production: MyClient?

                static func production() -> MyClient {
                    let production = _production ?? MyClient()

                    if _production == nil {
                        _production = production
                    }

                    return production
                }

                func witness() -> MyClient.Witness {
                    MyClient.Witness(
                        isThing: isThing
                    )
                }
            }
            """
        }
    }
    
    func testMacro_addsGetterToWitness_whenPropertyHasGetter_andGetterHasExplicitGetWrapper() throws {
        assertMacro {
            """
            @Witnessing
            struct MyClient {
                var isThing: Bool { 
                    get { true }
                }
            }
            """
        } expansion: {
            """
            struct MyClient {
                var isThing: Bool { 
                    get { true }
                }

                struct Witness {
                    var _isThing: Bool

                    var isThing: Bool {
                        get {
                            _isThing
                        }
                    }

                    init(isThing: Bool) {
                        _isThing = isThing
                    }


                }
            }

            extension MyClient {
                private static var _production: MyClient?

                static func production() -> MyClient {
                    let production = _production ?? MyClient()

                    if _production == nil {
                        _production = production
                    }

                    return production
                }

                func witness() -> MyClient.Witness {
                    MyClient.Witness(
                        isThing: isThing
                    )
                }
            }
            """
        }
    }
}

// MARK: Async getter

extension ProtocolWitnessingTests {
    func testMacro_addsAsyncGetterToWitness_whenPropertyHasAsyncGetter_andSpansOneLineOnly() throws {
        assertMacro {
            """
            @Witnessing
            struct MyClient {
                var isAsync: Bool {
                    get async { true }
                }
            }
            """
        } expansion: {
            """
            struct MyClient {
                var isAsync: Bool {
                    get async { true }
                }

                struct Witness {
                    var _isAsync: Bool

                    var isAsync: Bool {
                        get async {
                            _isAsync
                        }
                    }

                    init(isAsync: Bool) {
                        _isAsync = isAsync
                    }


                }
            }

            extension MyClient {
                private static var _production: MyClient?

                static func production() async -> MyClient {
                    let production = _production ?? MyClient()

                    if _production == nil {
                        _production = production
                    }

                    return production
                }

                func witness() async -> MyClient.Witness {
                    MyClient.Witness(
                        isAsync: await isAsync
                    )
                }
            }
            """
        }
    }
    
    func testMacro_addsAsyncGetterToWitness_whenPropertyHasAsyncGetter_andSpansMultipleLines() throws {
        assertMacro {
            """
            @Witnessing
            struct MyClient {
                var isAsync: Bool {
                    get async {
                        true
                    }
                }
            }
            """
        } expansion: {
            """
            struct MyClient {
                var isAsync: Bool {
                    get async {
                        true
                    }
                }

                struct Witness {
                    var _isAsync: Bool

                    var isAsync: Bool {
                        get async {
                            _isAsync
                        }
                    }

                    init(isAsync: Bool) {
                        _isAsync = isAsync
                    }


                }
            }

            extension MyClient {
                private static var _production: MyClient?

                static func production() async -> MyClient {
                    let production = _production ?? MyClient()

                    if _production == nil {
                        _production = production
                    }

                    return production
                }

                func witness() async -> MyClient.Witness {
                    MyClient.Witness(
                        isAsync: await isAsync
                    )
                }
            }
            """
        }
    }
    
    func testMacro_addsAsyncGetterToWitness_whenPropertyHasAsyncGetter_andGetterContainsComplexCode() throws {
        assertMacro {
            """
            @Witnessing
            struct MyClient {
                var isThing: Bool {
                    get async {
                        let myThing = true
                
                        print(myThing)
                
                        return myThing
                    }
                }
            }
            """
        } expansion: {
            """
            struct MyClient {
                var isThing: Bool {
                    get async {
                        let myThing = true
                
                        print(myThing)
                
                        return myThing
                    }
                }

                struct Witness {
                    var _isThing: Bool

                    var isThing: Bool {
                        get async {
                            _isThing
                        }
                    }

                    init(isThing: Bool) {
                        _isThing = isThing
                    }


                }
            }

            extension MyClient {
                private static var _production: MyClient?

                static func production() async -> MyClient {
                    let production = _production ?? MyClient()

                    if _production == nil {
                        _production = production
                    }

                    return production
                }

                func witness() async -> MyClient.Witness {
                    MyClient.Witness(
                        isThing: await isThing
                    )
                }
            }
            """
        }
    }
}

// MARK: Throwing getter

extension ProtocolWitnessingTests {
    func testMacro_addsThrowsGetterToWitness_whenPropertyHasThrowsGetter_andSpansOneLineOnly() throws {
        assertMacro {
            """
            @Witnessing
            struct MyClient {
                var isAsync: Bool {
                    get throws { true }
                }
            }
            """
        } expansion: {
            """
            struct MyClient {
                var isAsync: Bool {
                    get throws { true }
                }

                struct Witness {
                    var _isAsync: () throws -> Bool

                    var isAsync: Bool {
                        get throws {
                            try _isAsync()
                        }
                    }

                    init(isAsync: @escaping () throws -> Bool) {
                        _isAsync = isAsync
                    }


                }
            }

            extension MyClient {
                private static var _production: MyClient?

                static func production() throws -> MyClient {
                    let production = _production ?? MyClient()

                    if _production == nil {
                        _production = production
                    }

                    return production
                }

                func witness() throws -> MyClient.Witness {
                    MyClient.Witness(
                        isAsync: {
                            try isAsync
                        }
                    )
                }
            }
            """
        }
    }
    
    func testMacro_addsThrowsGetterToWitness_whenPropertyHasThrowsGetter_andSpansMultipleLines() throws {
        assertMacro {
            """
            @Witnessing
            struct MyClient {
                var isAsync: Bool {
                    get throws { 
                        true
                    }
                }
            }
            """
        } expansion: {
            """
            struct MyClient {
                var isAsync: Bool {
                    get throws { 
                        true
                    }
                }

                struct Witness {
                    var _isAsync: () throws -> Bool

                    var isAsync: Bool {
                        get throws {
                            try _isAsync()
                        }
                    }

                    init(isAsync: @escaping () throws -> Bool) {
                        _isAsync = isAsync
                    }


                }
            }

            extension MyClient {
                private static var _production: MyClient?

                static func production() throws -> MyClient {
                    let production = _production ?? MyClient()

                    if _production == nil {
                        _production = production
                    }

                    return production
                }

                func witness() throws -> MyClient.Witness {
                    MyClient.Witness(
                        isAsync: {
                            try isAsync
                        }
                    )
                }
            }
            """
        }
    }
}

// MARK: Setter

extension ProtocolWitnessingTests {
    func testMacro_addsSetterToWitness_whenPropertyHasGetterAndSetter_andSetterSpansOneLineOnly() throws {
        assertMacro {
            """
            @Witnessing
            struct MyClient {
                var isThing: Bool {
                    get { true }
                    set { print(newValue) }
                }
            }
            """
        } expansion: {
            """
            struct MyClient {
                var isThing: Bool {
                    get { true }
                    set { print(newValue) }
                }

                struct Witness {
                    var _isThing: Bool

                    var isThing: Bool {
                        get {
                            _isThing
                        }
                        set {
                            print(newValue)
                        }
                    }

                    init(isThing: Bool) {
                        _isThing = isThing
                    }


                }
            }

            extension MyClient {
                private static var _production: MyClient?

                static func production() -> MyClient {
                    let production = _production ?? MyClient()

                    if _production == nil {
                        _production = production
                    }

                    return production
                }

                func witness() -> MyClient.Witness {
                    MyClient.Witness(
                        isThing: isThing
                    )
                }
            }
            """
        }
    }
    
    func testMacro_addsSetterToWitness_whenPropertyHasGetterAndSetter_andSetterSpansMultipleLines() throws {
        assertMacro {
            """
            @Witnessing
            struct MyClient {
                var isThing: Bool {
                    get { true }
                    set { 
                        print(newValue)
                    }
                }
            }
            """
        } expansion: {
            """
            struct MyClient {
                var isThing: Bool {
                    get { true }
                    set { 
                        print(newValue)
                    }
                }

                struct Witness {
                    var _isThing: Bool

                    var isThing: Bool {
                        get {
                            _isThing
                        }
                        set {
                                    print(newValue)
                                }
                    }

                    init(isThing: Bool) {
                        _isThing = isThing
                    }


                }
            }

            extension MyClient {
                private static var _production: MyClient?

                static func production() -> MyClient {
                    let production = _production ?? MyClient()

                    if _production == nil {
                        _production = production
                    }

                    return production
                }

                func witness() -> MyClient.Witness {
                    MyClient.Witness(
                        isThing: isThing
                    )
                }
            }
            """
        }
    }
    
    func testMacro_addsSetterToWitness_whenPropertyHasGetterAndSetter_andSetterIsComplex() throws {
        assertMacro {
            """
            @Witnessing
            struct MyClient {
                var isThing: Bool {
                    get { true }
                    set {
                        let thing = 443
                        let thing2 = thing * (newValue ? 1 : 0)
            
                        print(thing2)
                    }
                }
            }
            """
        } expansion: {
            """
            struct MyClient {
                var isThing: Bool {
                    get { true }
                    set {
                        let thing = 443
                        let thing2 = thing * (newValue ? 1 : 0)

                        print(thing2)
                    }
                }

                struct Witness {
                    var _isThing: Bool

                    var isThing: Bool {
                        get {
                            _isThing
                        }
                        set {
                                    let thing = 443
                                    let thing2 = thing * (newValue ? 1 : 0)

                                    print(thing2)
                                }
                    }

                    init(isThing: Bool) {
                        _isThing = isThing
                    }


                }
            }

            extension MyClient {
                private static var _production: MyClient?

                static func production() -> MyClient {
                    let production = _production ?? MyClient()

                    if _production == nil {
                        _production = production
                    }

                    return production
                }

                func witness() -> MyClient.Witness {
                    MyClient.Witness(
                        isThing: isThing
                    )
                }
            }
            """
        }
    }
}

// MARK: Mix of computed

extension ProtocolWitnessingTests {
    func testMacro_addsGettersToWitness_whenPropertyHasAsyncGetter_andPropertyAlsoHasNonAsyncGetter() throws {
        assertMacro {
            """
            @Witnessing
            struct MyClient {
                var isThing: Bool {
                    get { true }
                }
                
                var isAsync: Bool {
                    get async { true }
                }
            }
            """
        } expansion: {
            """
            struct MyClient {
                var isThing: Bool {
                    get { true }
                }
                
                var isAsync: Bool {
                    get async { true }
                }

                struct Witness {
                    var _isThing: Bool
                    var _isAsync: Bool

                    var isThing: Bool {
                        get {
                            _isThing
                        }
                    }

                    var isAsync: Bool {
                        get async {
                            _isAsync
                        }
                    }

                    init(
                        isThing: Bool,
                        isAsync: Bool
                    ) {
                        _isThing = isThing
                        _isAsync = isAsync
                    }


                }
            }

            extension MyClient {
                private static var _production: MyClient?

                static func production() async -> MyClient {
                    let production = _production ?? MyClient()

                    if _production == nil {
                        _production = production
                    }

                    return production
                }

                func witness() async -> MyClient.Witness {
                    MyClient.Witness(
                        isThing: isThing,
                        isAsync: await isAsync
                    )
                }
            }
            """
        }
    }
}

// MARK: - Mixed

// MARK: Properties and functions

extension ProtocolWitnessingTests {
    func testMacro_addsMixedInit_andMixedProperty_whenMixingFunctionsReturnTypes() throws {
        assertMacro {
            """
            class Thing {}
            @Witnessing
            struct MyClient {
                func returnsVoid() { }
                func returnsAThing() -> Thing { .init() }
            }
            """
        } expansion: {
            """
            class Thing {}
            struct MyClient {
                func returnsVoid() { }
                func returnsAThing() -> Thing { .init() }

                struct Witness {
                    var _returnsVoid: () -> Void
                    var _returnsAThing: () -> Thing

                    init(
                        returnsVoid: @escaping () -> Void,
                        returnsAThing: @escaping () -> Thing
                    ) {
                        _returnsVoid = returnsVoid
                        _returnsAThing = returnsAThing
                    }

                    func returnsVoid() {
                        _returnsVoid()
                    }

                    func returnsAThing() -> Thing {
                        _returnsAThing()
                    }
                }
            }

            extension MyClient {
                private static var _production: MyClient?

                static func production() -> MyClient {
                    let production = _production ?? MyClient()

                    if _production == nil {
                        _production = production
                    }

                    return production
                }

                func witness() -> MyClient.Witness {
                    MyClient.Witness(
                        returnsVoid: returnsVoid,
                        returnsAThing: returnsAThing
                    )
                }
            }
            """
        }
    }
}

// MARK: Multiple macros

extension ProtocolWitnessingTests {
    func testMacro_expandsWithMainActor_whenAddingMainActorMacro_andWitnessMacro() throws {
        assertMacro {
            """
            class Thing {}
            
            @MainActor
            @Witnessing
            struct MyClient {
                func returnsVoid() { }
                func returnsAThing() -> Thing { .init() }
            }
            """
        } expansion: {
            """
            class Thing {}

            @MainActor
            struct MyClient {
                func returnsVoid() { }
                func returnsAThing() -> Thing { .init() }

                struct Witness {
                    var _returnsVoid: () -> Void
                    var _returnsAThing: () -> Thing

                    init(
                        returnsVoid: @escaping () -> Void,
                        returnsAThing: @escaping () -> Thing
                    ) {
                        _returnsVoid = returnsVoid
                        _returnsAThing = returnsAThing
                    }

                    func returnsVoid() {
                        _returnsVoid()
                    }

                    func returnsAThing() -> Thing {
                        _returnsAThing()
                    }
                }
            }

            extension MyClient {
                private static var _production: MyClient?

                static func production() -> MyClient {
                    let production = _production ?? MyClient()

                    if _production == nil {
                        _production = production
                    }

                    return production
                }

                func witness() -> MyClient.Witness {
                    MyClient.Witness(
                        returnsVoid: returnsVoid,
                        returnsAThing: returnsAThing
                    )
                }
            }
            """
        }
    }
}

// MARK: Macro killers

extension ProtocolWitnessingTests {
    func testMacro_expandsCorrectly_whenAddingAllTheThings() throws {
        assertMacro {
            #"""
            enum MyError: Error { case networkIssue }

            @MainActor
            class Thing {
                func doStuffHere() {
                    print("Updating UI")
                }
            }

            @Witnessing
            @MainActor
            struct MyClient {
                let id = UUID()
                var myThing: String
                let yourName: String
                
                func returnsTrue() -> Bool {
                    true
                }
                
                func returnsVoid() async {
                    print("doing async stuff for \(yourName)....")
                    try? await Task.sleep(nanoseconds: 2 * NSEC_PER_SEC)
                    print("async stuff done")
                }
                
                func returnsAThing() async throws -> Thing {
                    throw MyError.networkIssue
                }
            }
            """#
        } expansion: {
            #"""
            enum MyError: Error { case networkIssue }

            @MainActor
            class Thing {
                func doStuffHere() {
                    print("Updating UI")
                }
            }
            @MainActor
            struct MyClient {
                let id = UUID()
                var myThing: String
                let yourName: String
                
                func returnsTrue() -> Bool {
                    true
                }
                
                func returnsVoid() async {
                    print("doing async stuff for \(yourName)....")
                    try? await Task.sleep(nanoseconds: 2 * NSEC_PER_SEC)
                    print("async stuff done")
                }
                
                func returnsAThing() async throws -> Thing {
                    throw MyError.networkIssue
                }

                struct Witness {
                    var _myThing: String
                    var _yourName: String
                    var _returnsTrue: () -> Bool
                    var _returnsVoid: () async -> Void
                    var _returnsAThing: () async throws -> Thing

                    var yourName: String {
                        get {
                            _yourName
                        }
                    }

                    init(
                        myThing: String,
                        yourName: String,
                        returnsTrue: @escaping () -> Bool,
                        returnsVoid: @escaping () async -> Void,
                        returnsAThing: @escaping () async throws -> Thing
                    ) {
                        _myThing = myThing
                        _yourName = yourName
                        _returnsTrue = returnsTrue
                        _returnsVoid = returnsVoid
                        _returnsAThing = returnsAThing
                    }

                    func returnsTrue() -> Bool {
                        _returnsTrue()
                    }

                    func returnsVoid() async {
                        await _returnsVoid()
                    }

                    func returnsAThing() async throws -> Thing {
                        try await _returnsAThing()
                    }
                }
            }

            extension MyClient {
                private static var _production: MyClient?

                static func production(
                    myThing: String,
                    yourName: String
                ) -> MyClient {
                    let production = _production ?? MyClient(
                        myThing: myThing,
                        yourName: yourName
                    )

                    if _production == nil {
                        _production = production
                    }

                    return production
                }

                func witness() -> MyClient.Witness {
                    MyClient.Witness(
                        myThing: myThing,
                        yourName: yourName,
                        returnsTrue: returnsTrue,
                        returnsVoid: returnsVoid,
                        returnsAThing: returnsAThing
                    )
                }
            }
            """#
        }
    }
}

// MARK: - Arguments

// MARK: Custom witness type name

extension ProtocolWitnessingTests {
    func testMacro_usesWitnessForTypeName_whenTypeNameParameterIsNotSet() throws {
        assertMacro {
            """
            @Witnessing
            struct MyClient {
                func returnsVoid() { }
                func returnsAThing() -> Thing { }
            }
            """
        } expansion: {
            """
            struct MyClient {
                func returnsVoid() { }
                func returnsAThing() -> Thing { }

                struct Witness {
                    var _returnsVoid: () -> Void
                    var _returnsAThing: () -> Thing

                    init(
                        returnsVoid: @escaping () -> Void,
                        returnsAThing: @escaping () -> Thing
                    ) {
                        _returnsVoid = returnsVoid
                        _returnsAThing = returnsAThing
                    }

                    func returnsVoid() {
                        _returnsVoid()
                    }

                    func returnsAThing() -> Thing {
                        _returnsAThing()
                    }
                }
            }

            extension MyClient {
                private static var _production: MyClient?

                static func production() -> MyClient {
                    let production = _production ?? MyClient()

                    if _production == nil {
                        _production = production
                    }

                    return production
                }

                func witness() -> MyClient.Witness {
                    MyClient.Witness(
                        returnsVoid: returnsVoid,
                        returnsAThing: returnsAThing
                    )
                }
            }
            """
        }
    }
    
    func testMacro_usesCustomTypeName_whenTypeNameParameterIsSet_andTypeHasNoFunctions() throws {
        assertMacro {
            """
            @Witnessing("MyCustomWitnessTypeName")
            struct MyClient {
            
            }
            """
        } expansion: {
            """
            struct MyClient {

                struct MyCustomWitnessTypeName {
                    init() {

                    }
                }

            }

            extension MyClient {
                private static var _production: MyClient?

                static func production() -> MyClient {
                    let production = _production ?? MyClient()

                    if _production == nil {
                        _production = production
                    }

                    return production
                }

                func witness() -> MyClient.MyCustomWitnessTypeName {
                    MyClient.MyCustomWitnessTypeName()
                }
            }
            """
        }
    }
    
    func testMacro_usesCustomTypeName_whenTypeNameParameterIsSet_andTypeHasOneFunction() throws {
        assertMacro {
            """
            @Witnessing("MyCustomWitnessTypeName")
            struct MyClient {
                func myFunction() {}
            }
            """
        } expansion: {
            """
            struct MyClient {
                func myFunction() {}

                struct MyCustomWitnessTypeName {
                    var _myFunction: () -> Void

                    init(myFunction: @escaping () -> Void) {
                        _myFunction = myFunction
                    }

                    func myFunction() {
                        _myFunction()
                    }
                }
            }

            extension MyClient {
                private static var _production: MyClient?

                static func production() -> MyClient {
                    let production = _production ?? MyClient()

                    if _production == nil {
                        _production = production
                    }

                    return production
                }

                func witness() -> MyClient.MyCustomWitnessTypeName {
                    MyClient.MyCustomWitnessTypeName(
                        myFunction: myFunction
                    )
                }
            }
            """
        }
    }
}

// MARK: Custom production instance name

extension ProtocolWitnessingTests {
    func testMacro_usesProductionForTypeName_whenProductionInstanceNameParameterIsNotSet() throws {
        assertMacro {
            """
            @Witnessing
            struct MyClient {
                func returnsVoid() { }
            }
            """
        } expansion: {
            """
            struct MyClient {
                func returnsVoid() { }

                struct Witness {
                    var _returnsVoid: () -> Void

                    init(returnsVoid: @escaping () -> Void) {
                        _returnsVoid = returnsVoid
                    }

                    func returnsVoid() {
                        _returnsVoid()
                    }
                }
            }

            extension MyClient {
                private static var _production: MyClient?

                static func production() -> MyClient {
                    let production = _production ?? MyClient()

                    if _production == nil {
                        _production = production
                    }

                    return production
                }

                func witness() -> MyClient.Witness {
                    MyClient.Witness(
                        returnsVoid: returnsVoid
                    )
                }
            }
            """
        }
    }
    
    func testMacro_usesProductionForTypeNameAsTheInstanceName_whenProductionInstanceNameParameterIsSet() throws {
        assertMacro {
            """
            @Witnessing(productionInstanceName: "live")
            struct MyClient {
                func returnsVoid() { }
            }
            """
        } expansion: {
            """
            struct MyClient {
                func returnsVoid() { }

                struct Witness {
                    var _returnsVoid: () -> Void

                    init(returnsVoid: @escaping () -> Void) {
                        _returnsVoid = returnsVoid
                    }

                    func returnsVoid() {
                        _returnsVoid()
                    }
                }
            }

            extension MyClient {
                private static var _live: MyClient?

                static func live() -> MyClient {
                    let live = _live ?? MyClient()

                    if _live == nil {
                        _live = live
                    }

                    return live
                }

                func witness() -> MyClient.Witness {
                    MyClient.Witness(
                        returnsVoid: returnsVoid
                    )
                }
            }
            """
        }
    }
}

// MARK: - Misc.

extension ProtocolWitnessingTests {
    func testMacro_addsNestedTypes() throws {
        assertMacro {
            """
            @Witnessing
            struct MyClient {
                var id: Int = 1

                enum MyError: Error {
                    case errorOne
                    case errorTwo
                }

                func doSomething() throws {
                    print("Prod id", id)

                    throw MyError.errorTwo
                }
            }
            """
        } expansion: {
            """
            struct MyClient {
                var id: Int = 1

                enum MyError: Error {
                    case errorOne
                    case errorTwo
                }

                func doSomething() throws {
                    print("Prod id", id)

                    throw MyError.errorTwo
                }

                struct Witness {
                    var _id: Int
                    var _doSomething: () throws -> Void

                    init(
                        id: Int,
                        doSomething: @escaping () throws -> Void
                    ) {
                        _id = id
                        _doSomething = doSomething
                    }

                    func doSomething() throws {
                        try _doSomething()
                    }
                }
            }

            extension MyClient {
                private static var _production: MyClient?

                static func production(
                    id: Int
                ) -> MyClient {
                    let production = _production ?? MyClient(
                        id: id
                    )

                    if _production == nil {
                        _production = production
                    }

                    return production
                }

                func witness() -> MyClient.Witness {
                    MyClient.Witness(
                        id: id,
                        doSomething: doSomething
                    )
                }
            }
            """
        }
    }
}

// MARK: - Assistance

//extension ProtocolWitnessingTests {
//    func testMacroActualOutputByForcingRecordToTrue() throws {
//        assertMacro(record: true) {
//            """
//            @Witnessing
//            struct MyClient {
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//
//                struct Witness {
//                    init() {
//
//                    }
//                }
//            }
//
//            extension MyClient {
//                private static var _production = {
//                    Self.init()
//                }()
//
//                static var production = Witness(
//
//                )
//            }
//            """
//        }
//    }
//}
#else
final class ProtocolWitnessingTests: XCTestCase {
    func testMacro() throws {
        throw XCTSkip("macros are only supported when running tests for the host platform")
    }
}
#endif
