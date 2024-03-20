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
 - Function returns explicit void
    - Weird/unusual formatting?
 - Async/await functions/vars
 - production() returns non-mutable version with no "_" properties, separate name for witness? `witness()`
 - Nested types
 - Add fix it for non-struct type to convert type to a struct
 - Use SwiftSyntaxMacros builders?
 - Arg for using static var singleton vs _always_ creating on calling `production() {}`
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

                static func production() -> MyClient.Witness {
                    let production = _production ?? MyClient()

                    if _production == nil {
                        _production = production
                    }

                    return MyClient.Witness()
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

                static func production() -> MyClient.Witness {
                    let production = _production ?? MyClient()

                    if _production == nil {
                        _production = production
                    }

                    return MyClient.Witness(
                        doSomething: production.doSomething
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

                static func production() -> MyClient.Witness {
                    let production = _production ?? MyClient()

                    if _production == nil {
                        _production = production
                    }

                    return MyClient.Witness(
                        doSomething: production.doSomething
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

                static func production() -> MyClient.Witness {
                    let production = _production ?? MyClient()

                    if _production == nil {
                        _production = production
                    }

                    return MyClient.Witness(
                        doSomething: production.doSomething
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

                static func production() -> MyClient.Witness {
                    let production = _production ?? MyClient()

                    if _production == nil {
                        _production = production
                    }

                    return MyClient.Witness(
                        doSomething: production.doSomething
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

                static func production() -> MyClient.Witness {
                    let production = _production ?? MyClient()

                    if _production == nil {
                        _production = production
                    }

                    return MyClient.Witness(
                        doSomething: production.doSomething,
                        doAnotherThing: production.doAnotherThing
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

                static func production() -> MyClient.Witness {
                    let production = _production ?? MyClient()

                    if _production == nil {
                        _production = production
                    }

                    return MyClient.Witness(
                        doSomething: production.doSomething,
                        doAnotherThing: production.doAnotherThing
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

                static func production() -> MyClient.Witness {
                    let production = _production ?? MyClient()

                    if _production == nil {
                        _production = production
                    }

                    return MyClient.Witness(
                        doSomething: production.doSomething,
                        doAnotherThing: production.doAnotherThing
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

                static func production() -> MyClient.Witness {
                    let production = _production ?? MyClient()

                    if _production == nil {
                        _production = production
                    }

                    return MyClient.Witness(
                        doSomething: production.doSomething,
                        doAnotherThing: production.doAnotherThing
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
            
                static func production() -> MyClient.Witness {
                    let production = _production ?? MyClient()
            
                    if _production == nil {
                        _production = production
                    }
            
                    return MyClient.Witness(
                        doSomething: production.doSomething
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
            
                static func production() -> MyClient.Witness {
                    let production = _production ?? MyClient()
            
                    if _production == nil {
                        _production = production
                    }
            
                    return MyClient.Witness(
                        doSomething: production.doSomething
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
            
                static func production() -> MyClient.Witness {
                    let production = _production ?? MyClient()
            
                    if _production == nil {
                        _production = production
                    }
            
                    return MyClient.Witness(
                        doSomething: production.doSomething
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
            
                static func production() -> MyClient.Witness {
                    let production = _production ?? MyClient()
            
                    if _production == nil {
                        _production = production
                    }
            
                    return MyClient.Witness(
                        doSomething: production.doSomething
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

                    init(someLetProperty: Int) {
                        _someLetProperty = someLetProperty
                    }


                }
            }

            extension MyClient {
                private static var _production: MyClient?

                static func production(
                    someLetProperty: Int
                ) -> MyClient.Witness {
                    let production = _production ?? MyClient(
                        someLetProperty: someLetProperty
                    )

                    if _production == nil {
                        _production = production
                    }

                    return MyClient.Witness(
                        someLetProperty: production.someLetProperty
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
                ) -> MyClient.Witness {
                    let production = _production ?? MyClient(
                        someLetProperty: someLetProperty
                    )

                    if _production == nil {
                        _production = production
                    }

                    return MyClient.Witness(
                        someLetProperty: production.someLetProperty
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

                static func production() -> MyClient.Witness {
                    let production = _production ?? MyClient()

                    if _production == nil {
                        _production = production
                    }

                    return MyClient.Witness()
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

                static func production() -> MyClient.Witness {
                    let production = _production ?? MyClient()

                    if _production == nil {
                        _production = production
                    }

                    return MyClient.Witness()
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
                ) -> MyClient.Witness {
                    let production = _production ?? MyClient(
                        someLetProperty: someLetProperty
                    )

                    if _production == nil {
                        _production = production
                    }

                    return MyClient.Witness(
                        someLetProperty: production.someLetProperty,
                        doSomething: production.doSomething
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
                ) -> MyClient.Witness {
                    let production = _production ?? MyClient(
                        someLetProperty: someLetProperty
                    )

                    if _production == nil {
                        _production = production
                    }

                    return MyClient.Witness(
                        someLetProperty: production.someLetProperty,
                        doSomething: production.doSomething
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

                static func production() -> MyClient.Witness {
                    let production = _production ?? MyClient()

                    if _production == nil {
                        _production = production
                    }

                    return MyClient.Witness(
                        doSomething: production.doSomething
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

                static func production() -> MyClient.Witness {
                    let production = _production ?? MyClient()

                    if _production == nil {
                        _production = production
                    }

                    return MyClient.Witness(
                        doSomething: production.doSomething
                    )
                }
            }
            """
        }
    }
}

// MARK: - Mixed

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
            
                static func production() -> MyClient.Witness {
                    let production = _production ?? MyClient()
            
                    if _production == nil {
                        _production = production
                    }
            
                    return MyClient.Witness(
                        returnsVoid: production.returnsVoid,
                        returnsAThing: production.returnsAThing
                    )
                }
            }
            """
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

                static func production() -> MyClient.Witness {
                    let production = _production ?? MyClient()

                    if _production == nil {
                        _production = production
                    }

                    return MyClient.Witness(
                        returnsVoid: production.returnsVoid,
                        returnsAThing: production.returnsAThing
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

                static func production() -> MyClient.MyCustomWitnessTypeName {
                    let production = _production ?? MyClient()

                    if _production == nil {
                        _production = production
                    }

                    return MyClient.MyCustomWitnessTypeName()
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

                static func production() -> MyClient.MyCustomWitnessTypeName {
                    let production = _production ?? MyClient()

                    if _production == nil {
                        _production = production
                    }

                    return MyClient.MyCustomWitnessTypeName(
                        myFunction: production.myFunction
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

                static func production() -> MyClient.Witness {
                    let production = _production ?? MyClient()

                    if _production == nil {
                        _production = production
                    }

                    return MyClient.Witness(
                        returnsVoid: production.returnsVoid
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

                static func live() -> MyClient.Witness {
                    let live = _live ?? MyClient()

                    if _live == nil {
                        _live = live
                    }

                    return MyClient.Witness(
                        returnsVoid: live.returnsVoid
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
