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
 - function has closure parameters like a completion handler
 - struct has properties as well as funcs
 - Function returns explicit void
 - Weird/unusual formatting?
 - Using custom args
 - Add fix it for non-struct type to convert type to a struct
 - Async/await functions/vars
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
    func testMacro_addsEmptyInit_whenNoFunctions() throws {
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
                private static var _production: MyClient = {
                    Self.init()
                }()

                static var production = MyClient.Witness(

                )
            }
            """
        }
    }
}

// MARK: - One function

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
                private static var _production: MyClient = {
                    Self.init()
                }()

                static var production = MyClient.Witness(
                    doSomething: _production.doSomething
                )
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
                private static var _production: MyClient = {
                    Self.init()
                }()

                static var production = MyClient.Witness(
                    doSomething: _production.doSomething
                )
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
                private static var _production: MyClient = {
                    Self.init()
                }()

                static var production = MyClient.Witness(
                    doSomething: _production.doSomething
                )
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
                private static var _production: MyClient = {
                    Self.init()
                }()

                static var production = MyClient.Witness(
                    doSomething: _production.doSomething
                )
            }
            """
        }
    }
}

// MARK: - Two functions

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
                private static var _production: MyClient = {
                    Self.init()
                }()

                static var production = MyClient.Witness(
                    doSomething: _production.doSomething,
                    doAnotherThing: _production.doAnotherThing
                )
            }
            """
        }
    }
    
    func testMacro_addsInitWithParameterToVoidClosure_andPropertyForParameterToVoidClosure_whenTwoFunctions_andBothHaveOneArgument_andBothReturnsVoid() throws {
        assertMacro {
            """
            @Witnessing
            struct MyWitness {
                func doSomething(arg1: Type) { }
                func doAnotherThing(otherArg: OtherType) { }
            }
            """
        } expansion: {
            """
            struct MyWitness {
                func doSomething(arg1: Type) { }
                func doAnotherThing(otherArg: OtherType) { }

                struct Witness {
                    var _doSomething: (Type) -> Void
                    var _doAnotherThing: (OtherType) -> Void

                    init(
                        doSomething: @escaping (Type) -> Void,
                        doAnotherThing: @escaping (OtherType) -> Void
                    ) {
                        _doSomething = doSomething
                        _doAnotherThing = doAnotherThing
                    }

                    func doSomething(arg1: Type) {
                        _doSomething(arg1)
                    }

                    func doAnotherThing(otherArg: OtherType) {
                        _doAnotherThing(otherArg)
                    }
                }
            }

            extension MyWitness {
                private static var _production: MyWitness = {
                    Self.init()
                }()

                static var production = MyWitness.Witness(
                    doSomething: _production.doSomething,
                    doAnotherThing: _production.doAnotherThing
                )
            }
            """
        }
    }
    
    func testMacro_addsInitWithParameterToReturnValueClosure_andPropertyForParameterToReturnValueClosure_whenTwoFunctions_andBothHaveOneArgument_andBothReturnValues() throws {
        assertMacro {
            """
            @Witnessing
            struct MyWitness {
                func doSomething(arg1: Type) -> OtherType { }
                func doAnotherThing(otherArg: OtherType) -> Type { }
            }
            """
        } expansion: {
            """
            struct MyWitness {
                func doSomething(arg1: Type) -> OtherType { }
                func doAnotherThing(otherArg: OtherType) -> Type { }

                struct Witness {
                    var _doSomething: (Type) -> OtherType
                    var _doAnotherThing: (OtherType) -> Type

                    init(
                        doSomething: @escaping (Type) -> OtherType,
                        doAnotherThing: @escaping (OtherType) -> Type
                    ) {
                        _doSomething = doSomething
                        _doAnotherThing = doAnotherThing
                    }

                    func doSomething(arg1: Type) -> OtherType {
                        _doSomething(arg1)
                    }

                    func doAnotherThing(otherArg: OtherType) -> Type {
                        _doAnotherThing(otherArg)
                    }
                }
            }

            extension MyWitness {
                private static var _production: MyWitness = {
                    Self.init()
                }()

                static var production = MyWitness.Witness(
                    doSomething: _production.doSomething,
                    doAnotherThing: _production.doAnotherThing
                )
            }
            """
        }
    }
    
    func testMacro_addsInitWithParametersToReturnValueClosure_andPropertyForParameterToReturnValueClosure_whenTwoFunctions_andBothHaveTwoArguments_andBothReturnValues() throws {
        assertMacro {
            """
            @Witnessing
            struct MyWitness {
                func doSomething(arg1: Type, arg2: TypeTwo) -> OtherType { }
                func doAnotherThing(otherArg: OtherType, anotherArg: AnotherType) -> Type { }
            }
            """
        } expansion: {
            """
            struct MyWitness {
                func doSomething(arg1: Type, arg2: TypeTwo) -> OtherType { }
                func doAnotherThing(otherArg: OtherType, anotherArg: AnotherType) -> Type { }

                struct Witness {
                    var _doSomething: (Type, TypeTwo) -> OtherType
                    var _doAnotherThing: (OtherType, AnotherType) -> Type

                    init(
                        doSomething: @escaping (Type, TypeTwo) -> OtherType,
                        doAnotherThing: @escaping (OtherType, AnotherType) -> Type
                    ) {
                        _doSomething = doSomething
                        _doAnotherThing = doAnotherThing
                    }

                    func doSomething(arg1: Type, arg2: TypeTwo) -> OtherType {
                        _doSomething(arg1, arg2)
                    }

                    func doAnotherThing(otherArg: OtherType, anotherArg: AnotherType) -> Type {
                        _doAnotherThing(otherArg, anotherArg)
                    }
                }
            }

            extension MyWitness {
                private static var _production: MyWitness = {
                    Self.init()
                }()

                static var production = MyWitness.Witness(
                    doSomething: _production.doSomething,
                    doAnotherThing: _production.doAnotherThing
                )
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
            @Witnessing
            struct MyWitness {
                func returnsVoid() { }
                func returnsAThing() -> Thing { }
            }
            """
        } expansion: {
            """
            struct MyWitness {
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

            extension MyWitness {
                private static var _production: MyWitness = {
                    Self.init()
                }()

                static var production = MyWitness.Witness(
                    returnsVoid: _production.returnsVoid,
                    returnsAThing: _production.returnsAThing
                )
            }
            """
        }
    }
}

// MARK: - Parameters

extension ProtocolWitnessingTests {
    func testMacro_usesWitnessForTypeName_whenTypeNameParameterIsNotSet() throws {
        assertMacro {
            """
            @Witnessing
            struct MyWitness {
                func returnsVoid() { }
                func returnsAThing() -> Thing { }
            }
            """
        } expansion: {
            """
            struct MyWitness {
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

            extension MyWitness {
                private static var _production: MyWitness = {
                    Self.init()
                }()

                static var production = MyWitness.Witness(
                    returnsVoid: _production.returnsVoid,
                    returnsAThing: _production.returnsAThing
                )
            }
            """
        }
    }
    
    func testMacro_usesCustomTypeName_whenTypeNameParameterIsSet_andTypeHasNoFunctions() throws {
        assertMacro {
            """
            @Witnessing("MyCustomWitnessTypeName")
            struct MyWitness {
            
            }
            """
        } expansion: {
            """
            struct MyWitness {

                struct MyCustomWitnessTypeName {
                    init() {

                    }
                }

            }

            extension MyWitness {
                private static var _production: MyWitness = {
                    Self.init()
                }()

                static var production = MyWitness.MyCustomWitnessTypeName(

                )
            }
            """
        }
    }
    
    func testMacro_usesCustomTypeName_whenTypeNameParameterIsSet_andTypeHasOneFunction() throws {
        assertMacro {
            """
            @Witnessing("MyCustomWitnessTypeName")
            struct MyWitness {
                func myFunction() {}
            }
            """
        } expansion: {
            """
            struct MyWitness {
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

            extension MyWitness {
                private static var _production: MyWitness = {
                    Self.init()
                }()

                static var production = MyWitness.MyCustomWitnessTypeName(
                    myFunction: _production.myFunction
                )
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
