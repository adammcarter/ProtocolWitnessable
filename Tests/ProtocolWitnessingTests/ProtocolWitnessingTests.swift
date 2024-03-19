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
        withMacroTesting(macros: [
            "Witnessing": WitnessingMacro.self,
        ]) {
            super.invokeTest()
        }
    }
}

// MARK: - Initial sanity checking

extension ProtocolWitnessingTests {
    func testMacro_throwsError_whenAttachedToClass() throws {
        assertMacro {
            """
            @Witnessing
            class MyClass {
            }
            """
        } diagnostics: {
            """
            @Witnessing
            ┬──────────
            ╰─ 🛑 @Witnessing can only be attached to a struct
            class MyClass {
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
            struct MyWitness {
            }
            """
        } expansion: {
            """
            struct MyWitness {

                init() {

                }
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
            struct MyWitness {
                func doSomething() { }
            }
            """
        } expansion: {
            """
            struct MyWitness {
                func doSomething() { }
            
                var _doSomething: () -> Void
            
                init(doSomething: @escaping () -> Void) {
                    _doSomething = doSomething
                }
            }
            """
        }
    }
    
    func testMacro_addsInitWithParameterToVoidClosure_andPropertyForParameterToVoidClosure_whenOneFunction_andOneArgument_andReturnsVoid() throws {
        assertMacro {
            """
            @Witnessing
            struct MyWitness {
                func doSomething(int: Int) { }
            }
            """
        } expansion: {
            """
            struct MyWitness {
                func doSomething(int: Int) { }
            
                var _doSomething: (Int) -> Void
            
                init(doSomething: @escaping (Int) -> Void) {
                    _doSomething = doSomething
                }
            }
            """
        }
    }
    
    func testMacro_addsInitWithParameterToReturnValueClosure_andPropertyForParameterToReturnValueClosure_whenOneFunction_andOneArgument_andReturnValue() throws {
        assertMacro {
            """
            @Witnessing
            struct MyWitness {
                func doSomething(int: Int) -> Double { 0.5 }
            }
            """
        } expansion: {
            """
            struct MyWitness {
                func doSomething(int: Int) -> Double { 0.5 }
            
                var _doSomething: (Int) -> Double
            
                init(doSomething: @escaping (Int) -> Double) {
                    _doSomething = doSomething
                }
            }
            """
        }
    }
    
    func testMacro_addsInitWithParametersToReturnValueClosure_andPropertyForParameterToReturnValueClosure_whenOneFunction_andTwoArguments_andReturnValue() throws {
        assertMacro {
            """
            @Witnessing
            struct MyWitness {
                func doSomething(int: Int, float: Float) -> Double { 0.5 }
            }
            """
        } expansion: {
            """
            struct MyWitness {
                func doSomething(int: Int, float: Float) -> Double { 0.5 }
            
                var _doSomething: (Int, Float) -> Double
            
                init(doSomething: @escaping (Int, Float) -> Double) {
                    _doSomething = doSomething
                }
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
            struct MyWitness {
                func doSomething() { }
                func doAnotherThing() { }
            }
            """
        } expansion: {
            """
            struct MyWitness {
                func doSomething() { }
                func doAnotherThing() { }
            
                var _doSomething: () -> Void
                var _doAnotherThing: () -> Void
            
                init(
                    doSomething: @escaping () -> Void,
                    doAnotherThing: @escaping () -> Void
                ) {
                    _doSomething = doSomething
                    _doAnotherThing = doAnotherThing
                }
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
            
                var _doSomething: (Type) -> Void
                var _doAnotherThing: (OtherType) -> Void
            
                init(
                    doSomething: @escaping (Type) -> Void,
                    doAnotherThing: @escaping (OtherType) -> Void
                ) {
                    _doSomething = doSomething
                    _doAnotherThing = doAnotherThing
                }
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

                var _doSomething: (Type) -> OtherType
                var _doAnotherThing: (OtherType) -> Type
            
                init(
                    doSomething: @escaping (Type) -> OtherType,
                    doAnotherThing: @escaping (OtherType) -> Type
                ) {
                    _doSomething = doSomething
                    _doAnotherThing = doAnotherThing
                }
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

                var _doSomething: (Type, TypeTwo) -> OtherType
                var _doAnotherThing: (OtherType, AnotherType) -> Type
            
                init(
                    doSomething: @escaping (Type, TypeTwo) -> OtherType,
                    doAnotherThing: @escaping (OtherType, AnotherType) -> Type
                ) {
                    _doSomething = doSomething
                    _doAnotherThing = doAnotherThing
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

                var _returnsVoid: () -> Void
                var _returnsAThing: () -> Thing
            
                init(
                    returnsVoid: @escaping () -> Void,
                    returnsAThing: @escaping () -> Thing
                ) {
                    _returnsVoid = returnsVoid
                    _returnsAThing = returnsAThing
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
//            struct MyWitness {
//                func doSomething(int: Int) -> Double { 0.5 }
//            }
//            """
//        } expansion: {
//            """
//            struct MyWitness {
//                func doSomething(int: Int) -> Double { 0.5 }
//
//                var _doSomething: (Int) -> Double
//
//                init(doSomething: @escaping (Int) -> Double) {
//                    _doSomething = doSomething
//                }
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


/*
 - Function returns explicit void
 - Weird/unusual formatting?
 */
