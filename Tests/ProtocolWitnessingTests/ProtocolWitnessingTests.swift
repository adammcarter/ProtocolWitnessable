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
            "ProtocolWitnessing": WitnessingMacro.self,
        ]) {
            super.invokeTest()
        }
    }
}

/*
 TODO: Updates
 - Add support for attaching to actors and classes?
 - Erase type for production()?
 - Use SwiftSyntaxMacros builders?
 - Arg for overriding to not use a singleton and having `production() {}` create a new one each time
 - How does this work with the function passing in params? Weird we pass stuff in then potentially ignore it and return the singleton...
 - Use unique name generator helper for witness type name?
 - Replaces customising Witness type name?
 - Customise `witness()` function name with a new macro argument
 - Enable concurrency checking to "complete" mode - https://forums.swift.org/t/concurrency-checking-in-swift-packages-unsafeflags/61135
 - Use Swift Testing instead of XCTest
 - Refactor all the stuff
 - Produce a warning when let/var has no explicit type? fixit?
    - Or is there a way to detect the type automatically and put it in? Right now we just don't include the property in the witness
 - Create witnesses for test, preview, preproduction from the production variant by default
 - Inverse this? Change architecture to a struct that declares empty functions and a macro that expands on this, creating a production one and various others?
 */

// MARK: - Attachment checking

extension ProtocolWitnessingTests {
    func testMacro_throwsError_whenAttachedToStruct() throws {
        assertMacro {
            """
            @ProtocolWitnessing
            struct MyClient { }
            """
        } diagnostics: {
            """
            @ProtocolWitnessing
            ┬──────────────────
            ╰─ 🛑 @ProtocolWitnessing can only be attached to protocols
            struct MyClient { }
            """
        }
    }
    
    func testMacro_throwsError_whenAttachedToClass() throws {
        assertMacro {
            """
            @ProtocolWitnessing
            class MyClient { }
            """
        } diagnostics: {
            """
            @ProtocolWitnessing
            ┬──────────────────
            ╰─ 🛑 @ProtocolWitnessing can only be attached to protocols
            class MyClient { }
            """
        }
    }
    
    func testMacro_throwsError_whenAttachedToActor() throws {
        assertMacro {
            """
            @ProtocolWitnessing
            actor MyClient { }
            """
        } diagnostics: {
            """
            @ProtocolWitnessing
            ┬──────────────────
            ╰─ 🛑 @ProtocolWitnessing can only be attached to protocols
            actor MyClient { }
            """
        }
    }
    
    func testMacro_throwsError_whenAttachedToEnum() throws {
        assertMacro {
            """
            @ProtocolWitnessing
            enum MyClient { }
            """
        } diagnostics: {
            """
            @ProtocolWitnessing
            ┬──────────────────
            ╰─ 🛑 @ProtocolWitnessing can only be attached to protocols
            enum MyClient { }
            """
        }
    }
}

// MARK: - Empty structure

extension ProtocolWitnessingTests {
    func testMacro_createsEmptyStruct_andEmptyExtensionOnProtocol_whenProtocolIsEmpty_andProtocolIsImplicitlyInternal() throws {
        assertMacro {
            """
            @ProtocolWitnessing
            protocol MyClient { }
            """
        } expansion: {
            """
            protocol MyClient { }

            struct MyClientProtocolWitness: MyClient {
            }

            extension MyClient {
                static func makeErasedProtocolWitness() -> MyClient {
                    MyClientProtocolWitness()
                }

                func makingProtocolWitness() -> MyClientProtocolWitness {
                    MyClientProtocolWitness()
                }
            }
            """
        }
    }
    
    func testMacro_createsEmptyStruct_andEmptyExtensionOnProtocol_whenProtocolIsEmpty_andProtocolIsExplicitlyInternal() throws {
        assertMacro {
            """
            @ProtocolWitnessing
            internal protocol MyClient { }
            """
        } expansion: {
            """
            internal protocol MyClient { }

            internal struct MyClientProtocolWitness: MyClient {
            }

            internal extension MyClient {
                static func makeErasedProtocolWitness() -> MyClient {
                    MyClientProtocolWitness()
                }

                func makingProtocolWitness() -> MyClientProtocolWitness {
                    MyClientProtocolWitness()
                }
            }
            """
        }
    }
    
    func testMacro_createsEmptyStruct_andEmptyExtensionOnProtocol_whenProtocolIsEmpty_andProtocolIsExplicitlyPublic() throws {
        assertMacro {
            """
            @ProtocolWitnessing
            public protocol MyClient { }
            """
        } expansion: {
            """
            public protocol MyClient { }

            public struct MyClientProtocolWitness: MyClient {
            }

            public extension MyClient {
                static func makeErasedProtocolWitness() -> MyClient {
                    MyClientProtocolWitness()
                }

                func makingProtocolWitness() -> MyClientProtocolWitness {
                    MyClientProtocolWitness()
                }
            }
            """
        }
    }
    
    func testMacro_createsEmptyStruct_andEmptyExtensionOnProtocol_whenProtocolIsEmpty_andProtocolIsExplicitlyPrivate() throws {
        assertMacro {
            """
            @ProtocolWitnessing
            private protocol MyClient { }
            """
        } expansion: {
            """
            private protocol MyClient { }

            private struct MyClientProtocolWitness: MyClient {
            }

            private extension MyClient {
                static func makeErasedProtocolWitness() -> MyClient {
                    MyClientProtocolWitness()
                }

                func makingProtocolWitness() -> MyClientProtocolWitness {
                    MyClientProtocolWitness()
                }
            }
            """
        }
    }
    
    func testMacro_createsEmptyStruct_andEmptyExtensionOnProtocol_whenProtocolIsEmpty_andProtocolIsExplicitlyFileprivate() throws {
        assertMacro {
            """
            @ProtocolWitnessing
            fileprivate protocol MyClient { }
            """
        } expansion: {
            """
            fileprivate protocol MyClient { }

            fileprivate struct MyClientProtocolWitness: MyClient {
            }

            fileprivate extension MyClient {
                static func makeErasedProtocolWitness() -> MyClient {
                    MyClientProtocolWitness()
                }

                func makingProtocolWitness() -> MyClientProtocolWitness {
                    MyClientProtocolWitness()
                }
            }
            """
        }
    }
}

// MARK: - Functions

// MARK: One

extension ProtocolWitnessingTests {
    func testMacro_addsWrappedFunction_andProperty_andInitializerParameters_whenOneFunction_andInstanceFunc_andNoArguments_andImplicitlyReturnsVoid_andImplicitlyInternal() throws {
        assertMacro {
            """
            @ProtocolWitnessing
            protocol MyClient {
                func doSomething()
            }
            """
        } expansion: {
            """
            protocol MyClient {
                func doSomething()
            }

            struct MyClientProtocolWitness: MyClient {
                func doSomething() {
                    _doSomething()
                }

                var _doSomething: () -> Void
            }

            extension MyClient {
                static func makeErasedProtocolWitness(
                    doSomething: @escaping () -> Void
                ) -> MyClient {
                    MyClientProtocolWitness(
                        _doSomething: doSomething
                    )
                }

                func makingProtocolWitness() -> MyClientProtocolWitness {
                    MyClientProtocolWitness(
                        _doSomething: doSomething
                    )
                }
            }
            """
        }
    }
    
    func testMacro_addsWrappedFunction_andProperty_andInitializerParameters_whenOneFunction_andInstanceFunc_andOneArgument_andImplicitlyReturnsVoid_andImplicitlyInternal() throws {
        assertMacro {
            """
            @ProtocolWitnessing
            protocol MyClient {
                func doSomething(someInt: Int)
            }
            """
        } expansion: {
            """
            protocol MyClient {
                func doSomething(someInt: Int)
            }

            struct MyClientProtocolWitness: MyClient {
                func doSomething(someInt: Int) {
                    _doSomething(someInt)
                }

                var _doSomething: (Int) -> Void
            }

            extension MyClient {
                static func makeErasedProtocolWitness(
                    doSomething: @escaping (Int) -> Void
                ) -> MyClient {
                    MyClientProtocolWitness(
                        _doSomething: doSomething
                    )
                }

                func makingProtocolWitness() -> MyClientProtocolWitness {
                    MyClientProtocolWitness(
                        _doSomething: doSomething
                    )
                }
            }
            """
        }
    }
    
    func testMacro_addsWrappedFunction_andProperty_andInitializerParameters_whenOneFunction_andInstanceFunc_andTwoArguments_andImplicitlyReturnsVoid_andImplicitlyInternal() throws {
        assertMacro {
            """
            @ProtocolWitnessing
            protocol MyClient {
                func doSomething(someInt: Int, otherArg: String)
            }
            """
        } expansion: {
            """
            protocol MyClient {
                func doSomething(someInt: Int, otherArg: String)
            }

            struct MyClientProtocolWitness: MyClient {
                func doSomething(someInt: Int, otherArg: String) {
                    _doSomething(someInt, otherArg)
                }

                var _doSomething: (Int, String) -> Void
            }

            extension MyClient {
                static func makeErasedProtocolWitness(
                    doSomething: @escaping (Int, String) -> Void
                ) -> MyClient {
                    MyClientProtocolWitness(
                        _doSomething: doSomething
                    )
                }

                func makingProtocolWitness() -> MyClientProtocolWitness {
                    MyClientProtocolWitness(
                        _doSomething: doSomething
                    )
                }
            }
            """
        }
    }
    
    func testMacro_addsWrappedFunction_andProperty_andInitializerParameters_whenOneFunction_andInstanceFunc_andNoArguments_andExplicitlyReturnsVoid_andImplicitlyInternal() throws {
        assertMacro {
            """
            @ProtocolWitnessing
            protocol MyClient {
                func doSomething() -> Void
            }
            """
        } expansion: {
            """
            protocol MyClient {
                func doSomething() -> Void
            }
            
            struct MyClientProtocolWitness: MyClient {
                func doSomething() -> Void {
                    _doSomething()
                }
            
                var _doSomething: () -> Void
            }
            
            extension MyClient {
                static func makeErasedProtocolWitness(
                    doSomething: @escaping () -> Void
                ) -> MyClient {
                    MyClientProtocolWitness(
                        _doSomething: doSomething
                    )
                }
            
                func makingProtocolWitness() -> MyClientProtocolWitness {
                    MyClientProtocolWitness(
                        _doSomething: doSomething
                    )
                }
            }
            """
        }
    }
    
    func testMacro_addsWrappedFunction_andProperty_andInitializerParameters_whenOneFunction_andInstanceFunc_andNoArguments_andExplicitlyReturnsInt_andImplicitlyInternal() throws {
        assertMacro {
            """
            @ProtocolWitnessing
            protocol MyClient {
                func doSomething() -> Int
            }
            """
        } expansion: {
            """
            protocol MyClient {
                func doSomething() -> Int
            }
            
            struct MyClientProtocolWitness: MyClient {
                func doSomething() -> Int {
                    _doSomething()
                }
            
                var _doSomething: () -> Int
            }
            
            extension MyClient {
                static func makeErasedProtocolWitness(
                    doSomething: @escaping () -> Int
                ) -> MyClient {
                    MyClientProtocolWitness(
                        _doSomething: doSomething
                    )
                }
            
                func makingProtocolWitness() -> MyClientProtocolWitness {
                    MyClientProtocolWitness(
                        _doSomething: doSomething
                    )
                }
            }
            """
        }
    }
    
    func testMacro_addsWrappedFunction_andProperty_andInitializerParameters_whenOneFunction_andInstanceFunc_andNoArguments_andImplicitlyReturnsVoid_andExplicitlyInternal() throws {
        // This test makes no sense as we can't add internal funcs to protocols, we get a compiler error
    }
    
    func testMacro_addsWrappedFunction_andProperty_andInitializerParameters_whenOneFunction_andInstanceFunc_andNoArguments_andImplicitlyReturnsVoid_andExplicitlyPublic() throws {
        // This test makes no sense as we can't add public funcs to protocols, we get a compiler error
    }
    
    func testMacro_addsWrappedFunction_andProperty_andInitializerParameters_whenOneFunction_andInstanceFunc_andNoArguments_andImplicitlyReturnsVoid_andExplicitlyOpen() throws {
        // This test makes no sense as we can't add open funcs to protocols, we get a compiler error
    }
    
    func testMacro_doesNotAddWrappedFunction_andProperty_andInitializerParameters_whenOneFunction_andInstanceFunc_andNoArguments_andImplicitlyReturnsVoid_andExplicitlyFileprivate() throws {
        // This test makes no sense as we can't add fileprivate funcs to protocols, we get a compiler error
    }
    
    func testMacro_doesNotAddWrappedFunction_andProperty_andInitializerParameters_whenOneFunction_andInstanceFunc_andNoArguments_andImplicitlyReturnsVoid_andExplicitlyPrivate() throws {
        // This test makes no sense as we can't add private funcs to protocols, we get a compiler error
    }
    
    func testMacro_addsWrappedFunction_andProperty_butNoInitializerParameters_whenOneFunction_andStaticFunc_andNoArguments_andImplicitlyReturnsVoid_andImplicitlyInternal() throws {
        assertMacro {
            """
            @ProtocolWitnessing
            protocol MyClient {
                static func doSomething()
            }
            """
        } expansion: {
            """
            protocol MyClient {
                static func doSomething()
            }

            struct MyClientProtocolWitness: MyClient {
                static func doSomething() {
                    _doSomething()
                }
            
                static var _doSomething: () -> Void = {
                }
            }

            extension MyClient {
                static func makeErasedProtocolWitness() -> MyClient {
                    MyClientProtocolWitness()
                }
            
                func makingProtocolWitness() -> MyClientProtocolWitness {
                    MyClientProtocolWitness()
                }
            }
            """
        }
    }
    
    func testMacro_addsWrappedFunction_andProperty_butNoInitializerParameters_whenOneFunction_andStaticFunc_andOneArgument_andImplicitlyReturnsVoid_andImplicitlyInternal() throws {
        assertMacro {
            """
            @ProtocolWitnessing
            protocol MyClient {
                static func doSomething(int: Int)
            }
            """
        } expansion: {
            """
            protocol MyClient {
                static func doSomething(int: Int)
            }

            struct MyClientProtocolWitness: MyClient {
                static func doSomething(int: Int) {
                    _doSomething(int)
                }

                static var _doSomething: (Int) -> Void = { _ in
                }
            }

            extension MyClient {
                static func makeErasedProtocolWitness() -> MyClient {
                    MyClientProtocolWitness()
                }

                func makingProtocolWitness() -> MyClientProtocolWitness {
                    MyClientProtocolWitness()
                }
            }
            """
        }
    }
    
    func testMacro_addsWrappedFunction_andProperty_butNoInitializerParameters_whenOneFunction_andStaticFunc_andTwoArguments_andImplicitlyReturnsVoid_andImplicitlyInternal() throws {
        assertMacro {
            """
            @ProtocolWitnessing
            protocol MyClient {
                static func doSomething(int: Int, string: String)
            }
            """
        } expansion: {
            """
            protocol MyClient {
                static func doSomething(int: Int, string: String)
            }

            struct MyClientProtocolWitness: MyClient {
                static func doSomething(int: Int, string: String) {
                    _doSomething(int, string)
                }

                static var _doSomething: (Int, String) -> Void = { _, _ in
                }
            }

            extension MyClient {
                static func makeErasedProtocolWitness() -> MyClient {
                    MyClientProtocolWitness()
                }

                func makingProtocolWitness() -> MyClientProtocolWitness {
                    MyClientProtocolWitness()
                }
            }
            """
        }
    }
}

// MARK: Two (same)

extension ProtocolWitnessingTests {
    func testMacro_addsWrappedFunction_andProperty_andInitializerParameters_whenTwoFunctions_andInstanceFunc_andNoArguments_andImplicitlyReturnsVoid_andImplicitlyInternal() throws {
        assertMacro {
            """
            @ProtocolWitnessing
            protocol MyClient {
                func doSomething()
            
                func doAnotherThing()
            }
            """
        } expansion: {
            """
            protocol MyClient {
                func doSomething()

                func doAnotherThing()
            }

            struct MyClientProtocolWitness: MyClient {
                func doSomething() {
                    _doSomething()
                }

                var _doSomething: () -> Void

                func doAnotherThing() {
                    _doAnotherThing()
                }

                var _doAnotherThing: () -> Void
            }

            extension MyClient {
                static func makeErasedProtocolWitness(
                    doSomething: @escaping () -> Void,
                    doAnotherThing: @escaping () -> Void
                ) -> MyClient {
                    MyClientProtocolWitness(
                        _doSomething: doSomething,
                        _doAnotherThing: doAnotherThing
                    )
                }

                func makingProtocolWitness() -> MyClientProtocolWitness {
                    MyClientProtocolWitness(
                        _doSomething: doSomething,
                        _doAnotherThing: doAnotherThing
                    )
                }
            }
            """
        }
    }
    
    func testMacro_addsWrappedFunction_andProperty_andInitializerParameters_whenTwoFunctions_andInstanceFunc_andOneArgument_andImplicitlyReturnsVoid_andImplicitlyInternal() throws {
        assertMacro {
            """
            @ProtocolWitnessing
            protocol MyClient {
                func doSomething(someInt: Int)
            
                func doAnotherThing(otherString: String)
            }
            """
        } expansion: {
            """
            protocol MyClient {
                func doSomething(someInt: Int)

                func doAnotherThing(otherString: String)
            }

            struct MyClientProtocolWitness: MyClient {
                func doSomething(someInt: Int) {
                    _doSomething(someInt)
                }

                var _doSomething: (Int) -> Void

                func doAnotherThing(otherString: String) {
                    _doAnotherThing(otherString)
                }

                var _doAnotherThing: (String) -> Void
            }

            extension MyClient {
                static func makeErasedProtocolWitness(
                    doSomething: @escaping (Int) -> Void,
                    doAnotherThing: @escaping (String) -> Void
                ) -> MyClient {
                    MyClientProtocolWitness(
                        _doSomething: doSomething,
                        _doAnotherThing: doAnotherThing
                    )
                }

                func makingProtocolWitness() -> MyClientProtocolWitness {
                    MyClientProtocolWitness(
                        _doSomething: doSomething,
                        _doAnotherThing: doAnotherThing
                    )
                }
            }
            """
        }
    }
    
    func testMacro_addsWrappedFunction_andProperty_andInitializerParameters_whenTwoFunctions_andInstanceFunc_andTwoArguments_andImplicitlyReturnsVoid_andImplicitlyInternal() throws {
        assertMacro {
            """
            @ProtocolWitnessing
            protocol MyClient {
                func doSomething(someInt: Int, otherArg: String)
            
                func doAnotherThing(one: Int, two: Double)
            }
            """
        } expansion: {
            """
            protocol MyClient {
                func doSomething(someInt: Int, otherArg: String)

                func doAnotherThing(one: Int, two: Double)
            }

            struct MyClientProtocolWitness: MyClient {
                func doSomething(someInt: Int, otherArg: String) {
                    _doSomething(someInt, otherArg)
                }

                var _doSomething: (Int, String) -> Void

                func doAnotherThing(one: Int, two: Double) {
                    _doAnotherThing(one, two)
                }

                var _doAnotherThing: (Int, Double) -> Void
            }

            extension MyClient {
                static func makeErasedProtocolWitness(
                    doSomething: @escaping (Int, String) -> Void,
                    doAnotherThing: @escaping (Int, Double) -> Void
                ) -> MyClient {
                    MyClientProtocolWitness(
                        _doSomething: doSomething,
                        _doAnotherThing: doAnotherThing
                    )
                }

                func makingProtocolWitness() -> MyClientProtocolWitness {
                    MyClientProtocolWitness(
                        _doSomething: doSomething,
                        _doAnotherThing: doAnotherThing
                    )
                }
            }
            """
        }
    }
    
    func testMacro_addsWrappedFunction_andProperty_andInitializerParameters_whenTwoFunctions_andInstanceFunc_andNoArguments_andExplicitlyReturnsVoid_andImplicitlyInternal() throws {
        assertMacro {
            """
            @ProtocolWitnessing
            protocol MyClient {
                func doSomething() -> Void
            
                func doAnotherThing() -> Void
            }
            """
        } expansion: {
            """
            protocol MyClient {
                func doSomething() -> Void

                func doAnotherThing() -> Void
            }

            struct MyClientProtocolWitness: MyClient {
                func doSomething() -> Void {
                    _doSomething()
                }

                var _doSomething: () -> Void

                func doAnotherThing() -> Void {
                    _doAnotherThing()
                }

                var _doAnotherThing: () -> Void
            }

            extension MyClient {
                static func makeErasedProtocolWitness(
                    doSomething: @escaping () -> Void,
                    doAnotherThing: @escaping () -> Void
                ) -> MyClient {
                    MyClientProtocolWitness(
                        _doSomething: doSomething,
                        _doAnotherThing: doAnotherThing
                    )
                }

                func makingProtocolWitness() -> MyClientProtocolWitness {
                    MyClientProtocolWitness(
                        _doSomething: doSomething,
                        _doAnotherThing: doAnotherThing
                    )
                }
            }
            """
        }
    }
    
    func testMacro_addsWrappedFunction_andProperty_andInitializerParameters_whenTwoFunctions_andInstanceFunc_andNoArguments_andExplicitlyReturnsInt_andImplicitlyInternal() throws {
        assertMacro {
            """
            @ProtocolWitnessing
            protocol MyClient {
                func doSomething() -> Int
            
                func doAnotherThing() -> Double
            }
            """
        } expansion: {
            """
            protocol MyClient {
                func doSomething() -> Int

                func doAnotherThing() -> Double
            }

            struct MyClientProtocolWitness: MyClient {
                func doSomething() -> Int {
                    _doSomething()
                }

                var _doSomething: () -> Int

                func doAnotherThing() -> Double {
                    _doAnotherThing()
                }

                var _doAnotherThing: () -> Double
            }

            extension MyClient {
                static func makeErasedProtocolWitness(
                    doSomething: @escaping () -> Int,
                    doAnotherThing: @escaping () -> Double
                ) -> MyClient {
                    MyClientProtocolWitness(
                        _doSomething: doSomething,
                        _doAnotherThing: doAnotherThing
                    )
                }

                func makingProtocolWitness() -> MyClientProtocolWitness {
                    MyClientProtocolWitness(
                        _doSomething: doSomething,
                        _doAnotherThing: doAnotherThing
                    )
                }
            }
            """
        }
    }
    
    func testMacro_addsWrappedFunction_andProperty_andInitializerParameters_whenTwoFunctions_andInstanceFunc_andNoArguments_andImplicitlyReturnsVoid_andExplicitlyInternal() throws {
        // This test makes no sense as we can't add internal funcs to protocols, we get a compiler error
    }
    
    func testMacro_addsWrappedFunction_andProperty_andInitializerParameters_whenTwoFunctions_andInstanceFunc_andNoArguments_andImplicitlyReturnsVoid_andExplicitlyPublic() throws {
        // This test makes no sense as we can't add public funcs to protocols, we get a compiler error
    }
    
    func testMacro_addsWrappedFunction_andProperty_andInitializerParameters_whenTwoFunctions_andInstanceFunc_andNoArguments_andImplicitlyReturnsVoid_andExplicitlyOpen() throws {
        // This test makes no sense as we can't add open funcs to protocols, we get a compiler error
    }
    
    func testMacro_doesNotAddWrappedFunction_andProperty_andInitializerParameters_whenTwoFunctions_andInstanceFunc_andNoArguments_andImplicitlyReturnsVoid_andExplicitlyFileprivate() throws {
        // This test makes no sense as we can't add fileprivate funcs to protocols, we get a compiler error
    }
    
    func testMacro_doesNotAddWrappedFunction_andProperty_andInitializerParameters_whenTwoFunctions_andInstanceFunc_andNoArguments_andImplicitlyReturnsVoid_andExplicitlyPrivate() throws {
        // This test makes no sense as we can't add private funcs to protocols, we get a compiler error
    }
    
    func testMacro_addsWrappedFunction_andProperty_butNoInitializerParameters_whenTwoFunctions_andStaticFunc_andNoArguments_andImplicitlyReturnsVoid_andImplicitlyInternal() throws {
        assertMacro {
            """
            @ProtocolWitnessing
            protocol MyClient {
                static func doSomething()
            
                static func doAnotherThing()
            }
            """
        } expansion: {
            """
            protocol MyClient {
                static func doSomething()

                static func doAnotherThing()
            }

            struct MyClientProtocolWitness: MyClient {
                static func doSomething() {
                    _doSomething()
                }

                static var _doSomething: () -> Void = {
                }

                static func doAnotherThing() {
                    _doAnotherThing()
                }

                static var _doAnotherThing: () -> Void = {
                }
            }

            extension MyClient {
                static func makeErasedProtocolWitness() -> MyClient {
                    MyClientProtocolWitness()
                }

                func makingProtocolWitness() -> MyClientProtocolWitness {
                    MyClientProtocolWitness()
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
            @ProtocolWitnessing
            protocol MyClient {
                func doSomething() async
            }
            """
        } expansion: {
            """
            protocol MyClient {
                func doSomething() async
            }

            struct MyClientProtocolWitness: MyClient {
                func doSomething() async {
                    await _doSomething()
                }

                var _doSomething: () async -> Void
            }

            extension MyClient {
                static func makeErasedProtocolWitness(
                    doSomething: @escaping () async -> Void
                ) -> MyClient {
                    MyClientProtocolWitness(
                        _doSomething: doSomething
                    )
                }

                func makingProtocolWitness() -> MyClientProtocolWitness {
                    MyClientProtocolWitness(
                        _doSomething: doSomething
                    )
                }
            }
            """
        }
    }
    
    func testMacro_whenTwoFunctions_andBothFunctionsAreAsync() throws {
        assertMacro {
            """
            @ProtocolWitnessing
            protocol MyClient {
                func doSomething() async
            
                func doAnotherThing() async
            }
            """
        } expansion: {
            """
            protocol MyClient {
                func doSomething() async

                func doAnotherThing() async
            }

            struct MyClientProtocolWitness: MyClient {
                func doSomething() async {
                    await _doSomething()
                }

                var _doSomething: () async -> Void

                func doAnotherThing() async {
                    await _doAnotherThing()
                }

                var _doAnotherThing: () async -> Void
            }

            extension MyClient {
                static func makeErasedProtocolWitness(
                    doSomething: @escaping () async -> Void,
                    doAnotherThing: @escaping () async -> Void
                ) -> MyClient {
                    MyClientProtocolWitness(
                        _doSomething: doSomething,
                        _doAnotherThing: doAnotherThing
                    )
                }

                func makingProtocolWitness() -> MyClientProtocolWitness {
                    MyClientProtocolWitness(
                        _doSomething: doSomething,
                        _doAnotherThing: doAnotherThing
                    )
                }
            }
            """
        }
    }
    
    func testMacro_whenTwoFunctions_andOnlyOneFunctionsIsAsync() throws {
        assertMacro {
            """
            @ProtocolWitnessing
            protocol MyClient {
                func doSomething()
            
                func doAnotherThing() async
            }
            """
        } expansion: {
            """
            protocol MyClient {
                func doSomething()

                func doAnotherThing() async
            }

            struct MyClientProtocolWitness: MyClient {
                func doSomething() {
                    _doSomething()
                }

                var _doSomething: () -> Void

                func doAnotherThing() async {
                    await _doAnotherThing()
                }

                var _doAnotherThing: () async -> Void
            }

            extension MyClient {
                static func makeErasedProtocolWitness(
                    doSomething: @escaping () -> Void,
                    doAnotherThing: @escaping () async -> Void
                ) -> MyClient {
                    MyClientProtocolWitness(
                        _doSomething: doSomething,
                        _doAnotherThing: doAnotherThing
                    )
                }

                func makingProtocolWitness() -> MyClientProtocolWitness {
                    MyClientProtocolWitness(
                        _doSomething: doSomething,
                        _doAnotherThing: doAnotherThing
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
            @ProtocolWitnessing
            protocol MyClient {
                func doSomething() throws
            }
            """
        } expansion: {
            """
            protocol MyClient {
                func doSomething() throws
            }

            struct MyClientProtocolWitness: MyClient {
                func doSomething() throws {
                    try _doSomething()
                }

                var _doSomething: () throws -> Void
            }

            extension MyClient {
                static func makeErasedProtocolWitness(
                    doSomething: @escaping () throws -> Void
                ) -> MyClient {
                    MyClientProtocolWitness(
                        _doSomething: doSomething
                    )
                }

                func makingProtocolWitness() -> MyClientProtocolWitness {
                    MyClientProtocolWitness(
                        _doSomething: doSomething
                    )
                }
            }
            """
        }
    }
    
    func testMacro_whenTwoFunctions_andBothFunctionsAreThrowing() throws {
        assertMacro {
            """
            @ProtocolWitnessing
            protocol MyClient {
                func doSomething() throws
            
                func doSomethingElse() throws
            }
            """
        } expansion: {
            """
            protocol MyClient {
                func doSomething() throws

                func doSomethingElse() throws
            }

            struct MyClientProtocolWitness: MyClient {
                func doSomething() throws {
                    try _doSomething()
                }

                var _doSomething: () throws -> Void

                func doSomethingElse() throws {
                    try _doSomethingElse()
                }

                var _doSomethingElse: () throws -> Void
            }

            extension MyClient {
                static func makeErasedProtocolWitness(
                    doSomething: @escaping () throws -> Void,
                    doSomethingElse: @escaping () throws -> Void
                ) -> MyClient {
                    MyClientProtocolWitness(
                        _doSomething: doSomething,
                        _doSomethingElse: doSomethingElse
                    )
                }

                func makingProtocolWitness() -> MyClientProtocolWitness {
                    MyClientProtocolWitness(
                        _doSomething: doSomething,
                        _doSomethingElse: doSomethingElse
                    )
                }
            }
            """
        }
    }
    
    func testMacro_whenTwoFunctions_andOneFunctionIsThrowing_andOtherFunctionIsNot() throws {
        assertMacro {
            """
            @ProtocolWitnessing
            protocol MyClient {
                func doSomething()
            
                func doSomethingElse() throws
            }
            """
        } expansion: {
            """
            protocol MyClient {
                func doSomething()

                func doSomethingElse() throws
            }

            struct MyClientProtocolWitness: MyClient {
                func doSomething() {
                    _doSomething()
                }

                var _doSomething: () -> Void

                func doSomethingElse() throws {
                    try _doSomethingElse()
                }

                var _doSomethingElse: () throws -> Void
            }

            extension MyClient {
                static func makeErasedProtocolWitness(
                    doSomething: @escaping () -> Void,
                    doSomethingElse: @escaping () throws -> Void
                ) -> MyClient {
                    MyClientProtocolWitness(
                        _doSomething: doSomething,
                        _doSomethingElse: doSomethingElse
                    )
                }

                func makingProtocolWitness() -> MyClientProtocolWitness {
                    MyClientProtocolWitness(
                        _doSomething: doSomething,
                        _doSomethingElse: doSomethingElse
                    )
                }
            }
            """
        }
    }
}

// MARK: Completion handlers

extension ProtocolWitnessingTests {
    func testMacro_whenFunctionParametersContainsVoidToVoidClosure() throws {
        assertMacro {
            """
            @ProtocolWitnessing
            protocol MyClient {
                func doSomething(completionHandler: () -> Void)
            }
            """
        } expansion: {
            """
            protocol MyClient {
                func doSomething(completionHandler: () -> Void)
            }

            struct MyClientProtocolWitness: MyClient {
                func doSomething(completionHandler: () -> Void) {
                    _doSomething(completionHandler)
                }

                var _doSomething: (() -> Void) -> Void
            }

            extension MyClient {
                static func makeErasedProtocolWitness(
                    doSomething: @escaping (() -> Void) -> Void
                ) -> MyClient {
                    MyClientProtocolWitness(
                        _doSomething: doSomething
                    )
                }

                func makingProtocolWitness() -> MyClientProtocolWitness {
                    MyClientProtocolWitness(
                        _doSomething: doSomething
                    )
                }
            }
            """
        }
    }
    
    func testMacro_whenFunctionParametersContainsTypeToVoidClosure() throws {
        assertMacro {
            """
            @ProtocolWitnessing
            protocol MyClient {
                func doSomething(completionHandler: (Int) -> Void)
            }
            """
        } expansion: {
            """
            protocol MyClient {
                func doSomething(completionHandler: (Int) -> Void)
            }

            struct MyClientProtocolWitness: MyClient {
                func doSomething(completionHandler: (Int) -> Void) {
                    _doSomething(completionHandler)
                }

                var _doSomething: ((Int) -> Void) -> Void
            }

            extension MyClient {
                static func makeErasedProtocolWitness(
                    doSomething: @escaping ((Int) -> Void) -> Void
                ) -> MyClient {
                    MyClientProtocolWitness(
                        _doSomething: doSomething
                    )
                }

                func makingProtocolWitness() -> MyClientProtocolWitness {
                    MyClientProtocolWitness(
                        _doSomething: doSomething
                    )
                }
            }
            """
        }
    }
    
    func testMacro_whenFunctionParametersContainsTypeToVoidClosure_andTypeIsOptional() throws {
        assertMacro {
            """
            @ProtocolWitnessing
            protocol MyClient {
                func doSomething(completionHandler: (Int?) -> Void)
            }
            """
        } expansion: {
            """
            protocol MyClient {
                func doSomething(completionHandler: (Int?) -> Void)
            }

            struct MyClientProtocolWitness: MyClient {
                func doSomething(completionHandler: (Int?) -> Void) {
                    _doSomething(completionHandler)
                }

                var _doSomething: ((Int?) -> Void) -> Void
            }

            extension MyClient {
                static func makeErasedProtocolWitness(
                    doSomething: @escaping ((Int?) -> Void) -> Void
                ) -> MyClient {
                    MyClientProtocolWitness(
                        _doSomething: doSomething
                    )
                }

                func makingProtocolWitness() -> MyClientProtocolWitness {
                    MyClientProtocolWitness(
                        _doSomething: doSomething
                    )
                }
            }
            """
        }
    }
    
    func testMacro_whenFunctionParametersContainsMultipleVariousTypesToVoidClosure() throws {
        assertMacro {
            """
            @ProtocolWitnessing
            protocol MyClient {
                func doSomething(completionHandler: (Int, String, Double) -> Void)
            }
            """
        } expansion: {
            """
            protocol MyClient {
                func doSomething(completionHandler: (Int, String, Double) -> Void)
            }

            struct MyClientProtocolWitness: MyClient {
                func doSomething(completionHandler: (Int, String, Double) -> Void) {
                    _doSomething(completionHandler)
                }

                var _doSomething: ((Int, String, Double) -> Void) -> Void
            }

            extension MyClient {
                static func makeErasedProtocolWitness(
                    doSomething: @escaping ((Int, String, Double) -> Void) -> Void
                ) -> MyClient {
                    MyClientProtocolWitness(
                        _doSomething: doSomething
                    )
                }

                func makingProtocolWitness() -> MyClientProtocolWitness {
                    MyClientProtocolWitness(
                        _doSomething: doSomething
                    )
                }
            }
            """
        }
    }
    
    func testMacro_whenFunctionParametersContainsMultipleSameTypesToVoidClosure() throws {
        assertMacro {
            """
            @ProtocolWitnessing
            protocol MyClient {
                func doSomething(completionHandler: (Int, Int, Int) -> Void)
            }
            """
        } expansion: {
            """
            protocol MyClient {
                func doSomething(completionHandler: (Int, Int, Int) -> Void)
            }

            struct MyClientProtocolWitness: MyClient {
                func doSomething(completionHandler: (Int, Int, Int) -> Void) {
                    _doSomething(completionHandler)
                }

                var _doSomething: ((Int, Int, Int) -> Void) -> Void
            }

            extension MyClient {
                static func makeErasedProtocolWitness(
                    doSomething: @escaping ((Int, Int, Int) -> Void) -> Void
                ) -> MyClient {
                    MyClientProtocolWitness(
                        _doSomething: doSomething
                    )
                }

                func makingProtocolWitness() -> MyClientProtocolWitness {
                    MyClientProtocolWitness(
                        _doSomething: doSomething
                    )
                }
            }
            """
        }
    }
    
    func testMacro_whenFunctionParametersContainsVoidToVoidClosure_andIsEscaping() throws {
        assertMacro {
            """
            @ProtocolWitnessing
            protocol MyClient {
                func doSomething(completionHandler: @escaping () -> Void)
            }
            """
        } expansion: {
            """
            protocol MyClient {
                func doSomething(completionHandler: @escaping () -> Void)
            }

            struct MyClientProtocolWitness: MyClient {
                func doSomething(completionHandler: @escaping () -> Void) {
                    _doSomething(completionHandler)
                }

                var _doSomething: (@escaping () -> Void) -> Void
            }

            extension MyClient {
                static func makeErasedProtocolWitness(
                    doSomething: @escaping (@escaping () -> Void) -> Void
                ) -> MyClient {
                    MyClientProtocolWitness(
                        _doSomething: doSomething
                    )
                }

                func makingProtocolWitness() -> MyClientProtocolWitness {
                    MyClientProtocolWitness(
                        _doSomething: doSomething
                    )
                }
            }
            """
        }
    }
    
    func testMacro_whenFunctionParametersContainsTypeToVoidClosure_andIsEscaping() throws {
        assertMacro {
            """
            @ProtocolWitnessing
            protocol MyClient {
                func doSomething(completionHandler: @escaping (Int) -> Void)
            }
            """
        } expansion: {
            """
            protocol MyClient {
                func doSomething(completionHandler: @escaping (Int) -> Void)
            }

            struct MyClientProtocolWitness: MyClient {
                func doSomething(completionHandler: @escaping (Int) -> Void) {
                    _doSomething(completionHandler)
                }

                var _doSomething: (@escaping (Int) -> Void) -> Void
            }

            extension MyClient {
                static func makeErasedProtocolWitness(
                    doSomething: @escaping (@escaping (Int) -> Void) -> Void
                ) -> MyClient {
                    MyClientProtocolWitness(
                        _doSomething: doSomething
                    )
                }

                func makingProtocolWitness() -> MyClientProtocolWitness {
                    MyClientProtocolWitness(
                        _doSomething: doSomething
                    )
                }
            }
            """
        }
    }
    
    func testMacro_whenFunctionParametersContainsMultipleVoidToVoidClosures() throws {
        assertMacro {
            """
            @ProtocolWitnessing
            protocol MyClient {
                func doSomething(configurationHandler: () -> Void, completionHandler: () -> Void)
            }
            """
        } expansion: {
            """
            protocol MyClient {
                func doSomething(configurationHandler: () -> Void, completionHandler: () -> Void)
            }

            struct MyClientProtocolWitness: MyClient {
                func doSomething(configurationHandler: () -> Void, completionHandler: () -> Void) {
                    _doSomething(configurationHandler, completionHandler)
                }

                var _doSomething: (() -> Void, () -> Void) -> Void
            }

            extension MyClient {
                static func makeErasedProtocolWitness(
                    doSomething: @escaping (() -> Void, () -> Void) -> Void
                ) -> MyClient {
                    MyClientProtocolWitness(
                        _doSomething: doSomething
                    )
                }

                func makingProtocolWitness() -> MyClientProtocolWitness {
                    MyClientProtocolWitness(
                        _doSomething: doSomething
                    )
                }
            }
            """
        }
    }
    
    func testMacro_whenFunctionParametersContainsMultipleVoidToVoidClosures_andMixedParameters() throws {
        assertMacro {
            """
            @ProtocolWitnessing
            protocol MyClient {
                func doSomething(configurationHandler: () -> Void, completionHandler: (Bool, Error?) -> Void)
            }
            """
        } expansion: {
            """
            protocol MyClient {
                func doSomething(configurationHandler: () -> Void, completionHandler: (Bool, Error?) -> Void)
            }

            struct MyClientProtocolWitness: MyClient {
                func doSomething(configurationHandler: () -> Void, completionHandler: (Bool, Error?) -> Void) {
                    _doSomething(configurationHandler, completionHandler)
                }

                var _doSomething: (() -> Void, (Bool, Error?) -> Void) -> Void
            }

            extension MyClient {
                static func makeErasedProtocolWitness(
                    doSomething: @escaping (() -> Void, (Bool, Error?) -> Void) -> Void
                ) -> MyClient {
                    MyClientProtocolWitness(
                        _doSomething: doSomething
                    )
                }

                func makingProtocolWitness() -> MyClientProtocolWitness {
                    MyClientProtocolWitness(
                        _doSomething: doSomething
                    )
                }
            }
            """
        }
    }
}

// MARK: Funky code formatting

extension ProtocolWitnessingTests {
    func testMacro_expandsType_whenContainingFunction_andProtocolHasLotsOfWhitespaceAroundName() throws {
        assertMacro {
            """
            @ProtocolWitnessing
            protocol      MyClient     {
                func doSomething()   ->   Void
            }
            """
        } expansion: {
            """
            protocol      MyClient     {
                func doSomething()   ->   Void
            }

            struct MyClientProtocolWitness: MyClient {
                func doSomething() -> Void {
                    _doSomething()
                }

                var _doSomething: () -> Void
            }

            extension MyClient {
                static func makeErasedProtocolWitness(
                    doSomething: @escaping () -> Void
                ) -> MyClient {
                    MyClientProtocolWitness(
                        _doSomething: doSomething
                    )
                }

                func makingProtocolWitness() -> MyClientProtocolWitness {
                    MyClientProtocolWitness(
                        _doSomething: doSomething
                    )
                }
            }
            """
        }
    }
    
    func testMacro_expandsType_whenContainingFunction_andFunctionHasExtraWhitespaceAroundReturnArrow() throws {
        assertMacro {
            """
            @ProtocolWitnessing
            protocol MyClient {
                func doSomething()   ->   Void
            }
            """
        } expansion: {
            """
            protocol MyClient {
                func doSomething()   ->   Void
            }

            struct MyClientProtocolWitness: MyClient {
                func doSomething() -> Void {
                    _doSomething()
                }

                var _doSomething: () -> Void
            }

            extension MyClient {
                static func makeErasedProtocolWitness(
                    doSomething: @escaping () -> Void
                ) -> MyClient {
                    MyClientProtocolWitness(
                        _doSomething: doSomething
                    )
                }

                func makingProtocolWitness() -> MyClientProtocolWitness {
                    MyClientProtocolWitness(
                        _doSomething: doSomething
                    )
                }
            }
            """
        }
    }
    
    func testMacro_expandsType_whenContainingFunction_andFunctionHasExtraWhitespaceAroundFunctionName() throws {
        assertMacro {
            """
            @ProtocolWitnessing
            protocol MyClient {
                func    doSomething()
            }
            """
        } expansion: {
            """
            protocol MyClient {
                func    doSomething()
            }

            struct MyClientProtocolWitness: MyClient {
                func doSomething() {
                    _doSomething()
                }

                var _doSomething: () -> Void
            }

            extension MyClient {
                static func makeErasedProtocolWitness(
                    doSomething: @escaping () -> Void
                ) -> MyClient {
                    MyClientProtocolWitness(
                        _doSomething: doSomething
                    )
                }

                func makingProtocolWitness() -> MyClientProtocolWitness {
                    MyClientProtocolWitness(
                        _doSomething: doSomething
                    )
                }
            }
            """
        }
    }
    
    func testMacro_expandsType_whenContainingFunction_andFunctionHasExtraNewlinesAndWhitespaceEverywhere() throws {
        assertMacro {
            """
            @ProtocolWitnessing
            protocol MyClient {
                func    doSomething      (      )
                


            }
            """
        } expansion: {
            """
            protocol MyClient {
                func    doSomething      (      )
                


            }

            struct MyClientProtocolWitness: MyClient {
                func doSomething() {
                    _doSomething()
                }

                var _doSomething: () -> Void
            }

            extension MyClient {
                static func makeErasedProtocolWitness(
                    doSomething: @escaping () -> Void
                ) -> MyClient {
                    MyClientProtocolWitness(
                        _doSomething: doSomething
                    )
                }

                func makingProtocolWitness() -> MyClientProtocolWitness {
                    MyClientProtocolWitness(
                        _doSomething: doSomething
                    )
                }
            }
            """
        }
    }
}

// MARK: - Properties

// MARK: Simple

extension ProtocolWitnessingTests {
    func testMacro_createsUnderscoredVariable_andWrapsItWithGetOnlyVar_whenGetOnlyProperty() throws {
        assertMacro {
            """
            @ProtocolWitnessing
            protocol MyClient {
                var someLetProperty: Int { get }
            }
            """
        } expansion: {
            """
            protocol MyClient {
                var someLetProperty: Int { get }
            }

            struct MyClientProtocolWitness: MyClient {
                var someLetProperty: Int {
                    _someLetProperty
                }

                var _someLetProperty: Int
            }

            extension MyClient {
                static func makeErasedProtocolWitness(
                    someLetProperty: Int
                ) -> MyClient {
                    MyClientProtocolWitness(
                        _someLetProperty: someLetProperty
                    )
                }

                func makingProtocolWitness() -> MyClientProtocolWitness {
                    MyClientProtocolWitness(
                        _someLetProperty: someLetProperty
                    )
                }
            }
            """
        }
    }
    
    func testMacro_createsVariable_butWithoutWrapper_whenGetSetProperty() throws {
        assertMacro {
            """
            @ProtocolWitnessing
            protocol MyClient {
                var someLetProperty: Int { get set }
            }
            """
        } expansion: {
            """
            protocol MyClient {
                var someLetProperty: Int { get set }
            }

            struct MyClientProtocolWitness: MyClient {
                var someLetProperty: Int
            }

            extension MyClient {
                static func makeErasedProtocolWitness(
                    someLetProperty: Int
                ) -> MyClient {
                    MyClientProtocolWitness(
                        someLetProperty: someLetProperty
                    )
                }

                func makingProtocolWitness() -> MyClientProtocolWitness {
                    MyClientProtocolWitness(
                        someLetProperty: someLetProperty
                    )
                }
            }
            """
        }
    }
    
    func testMacro_createsVariableWithDefaultLazyClosure_whenGetOnlyProperty_andStatic() throws {
        assertMacro {
            """
            @ProtocolWitnessing
            protocol MyClient {
                static var someLetProperty: Int { get }
            }
            """
        } expansion: {
            """
            protocol MyClient {
                static var someLetProperty: Int { get }
            }

            struct MyClientProtocolWitness: MyClient {
                static var someLetProperty: Int = {
                    .init()
                }()
            }

            extension MyClient {
                static func makeErasedProtocolWitness() -> MyClient {
                    MyClientProtocolWitness()
                }
            
                func makingProtocolWitness() -> MyClientProtocolWitness {
                    MyClientProtocolWitness()
                }
            }
            """
        }
    }
    
    func testMacro_createsVariableWithDefaultLazyClosure_whenGetAndSetProperty_andStatic() throws {
        assertMacro {
            """
            @ProtocolWitnessing
            protocol MyClient {
                static var someLetProperty: Int { get set }
            }
            """
        } expansion: {
            """
            protocol MyClient {
                static var someLetProperty: Int { get set }
            }

            struct MyClientProtocolWitness: MyClient {
                static var someLetProperty: Int = {
                    .init()
                }()
            }

            extension MyClient {
                static func makeErasedProtocolWitness() -> MyClient {
                    MyClientProtocolWitness()
                }
            
                func makingProtocolWitness() -> MyClientProtocolWitness {
                    MyClientProtocolWitness()
                }
            }
            """
        }
    }
    
    func testMacro_createsUnderscoredVariable_andWrapsItWithGetOnlyVar_whenGetOnlyProperty_andIsClosureType() throws {
        assertMacro {
            """
            @ProtocolWitnessing
            protocol MyClient {
                var someLetProperty: () -> Void { get }
            }
            """
        } expansion: {
            """
            protocol MyClient {
                var someLetProperty: () -> Void { get }
            }

            struct MyClientProtocolWitness: MyClient {
                var someLetProperty: () -> Void {
                    _someLetProperty
                }

                var _someLetProperty: () -> Void
            }

            extension MyClient {
                static func makeErasedProtocolWitness(
                    someLetProperty: @escaping () -> Void
                ) -> MyClient {
                    MyClientProtocolWitness(
                        _someLetProperty: someLetProperty
                    )
                }

                func makingProtocolWitness() -> MyClientProtocolWitness {
                    MyClientProtocolWitness(
                        _someLetProperty: someLetProperty
                    )
                }
            }
            """
        }
    }
    
    func testMacro_createsVariable_whenGetSetProperty_andIsClosureType() throws {
        assertMacro {
            """
            @ProtocolWitnessing
            protocol MyClient {
                var someLetProperty: () -> Void { get set }
            }
            """
        } expansion: {
            """
            protocol MyClient {
                var someLetProperty: () -> Void { get set }
            }

            struct MyClientProtocolWitness: MyClient {
                var someLetProperty: () -> Void
            }

            extension MyClient {
                static func makeErasedProtocolWitness(
                    someLetProperty: @escaping () -> Void
                ) -> MyClient {
                    MyClientProtocolWitness(
                        someLetProperty: someLetProperty
                    )
                }

                func makingProtocolWitness() -> MyClientProtocolWitness {
                    MyClientProtocolWitness(
                        someLetProperty: someLetProperty
                    )
                }
            }
            """
        }
    }
    
    func testMacro_createsUnderscoredVariable_andWrapsItWithGetOnlyVar_whenGetOnlyProperty_andIsClosureType_andHasParameters() throws {
        assertMacro {
            """
            @ProtocolWitnessing
            protocol MyClient {
                var someLetProperty: (Int) -> Void { get }
            }
            """
        } expansion: {
            """
            protocol MyClient {
                var someLetProperty: (Int) -> Void { get }
            }

            struct MyClientProtocolWitness: MyClient {
                var someLetProperty: (Int) -> Void {
                    _someLetProperty
                }

                var _someLetProperty: (Int) -> Void
            }

            extension MyClient {
                static func makeErasedProtocolWitness(
                    someLetProperty: @escaping (Int) -> Void
                ) -> MyClient {
                    MyClientProtocolWitness(
                        _someLetProperty: someLetProperty
                    )
                }

                func makingProtocolWitness() -> MyClientProtocolWitness {
                    MyClientProtocolWitness(
                        _someLetProperty: someLetProperty
                    )
                }
            }
            """
        }
    }
    
    func testMacro_createsVariable_whenGetSetProperty_andIsClosureType_andHasParameters() throws {
        assertMacro {
            """
            @ProtocolWitnessing
            protocol MyClient {
                var someLetProperty: (Int) -> Void { get set }
            }
            """
        } expansion: {
            """
            protocol MyClient {
                var someLetProperty: (Int) -> Void { get set }
            }

            struct MyClientProtocolWitness: MyClient {
                var someLetProperty: (Int) -> Void
            }

            extension MyClient {
                static func makeErasedProtocolWitness(
                    someLetProperty: @escaping (Int) -> Void
                ) -> MyClient {
                    MyClientProtocolWitness(
                        someLetProperty: someLetProperty
                    )
                }

                func makingProtocolWitness() -> MyClientProtocolWitness {
                    MyClientProtocolWitness(
                        someLetProperty: someLetProperty
                    )
                }
            }
            """
        }
    }
}

// MARK: Async

extension ProtocolWitnessingTests {
    func testMacro_createsUnderscoredVariable_andWrapsItWithGetOnlyVar_whenGetOnlyProperty_andAsync() throws {
        assertMacro {
            """
            @ProtocolWitnessing
            protocol MyClient {
                var someLetProperty: Int { get async }
            }
            """
        } expansion: {
            """
            protocol MyClient {
                var someLetProperty: Int { get async }
            }
            
            struct MyClientProtocolWitness: MyClient {
                var someLetProperty: Int {
                    get async {
                        _someLetProperty
                    }
                }
            
                var _someLetProperty: Int
            }
            
            extension MyClient {
                static func makeErasedProtocolWitness(
                    someLetProperty: Int
                ) -> MyClient {
                    MyClientProtocolWitness(
                        _someLetProperty: someLetProperty
                    )
                }
            
                func makingProtocolWitness() async -> MyClientProtocolWitness {
                    await MyClientProtocolWitness(
                        _someLetProperty: someLetProperty
                    )
                }
            }
            """
        }
    }
    
    func testMacro_createsUnderscoredVariable_andWrapsItWithGetOnlyVar_whenGetOnlyProperty_andAsync_andIsClosure() throws {
        assertMacro {
            """
            @ProtocolWitnessing
            protocol MyClient {
                var someLetProperty: (Int) -> Void { get async }
            }
            """
        } expansion: {
            """
            protocol MyClient {
                var someLetProperty: (Int) -> Void { get async }
            }

            struct MyClientProtocolWitness: MyClient {
                var someLetProperty: (Int) -> Void {
                    get async {
                        _someLetProperty
                    }
                }

                var _someLetProperty: (Int) -> Void
            }

            extension MyClient {
                static func makeErasedProtocolWitness(
                    someLetProperty: @escaping (Int) -> Void
                ) -> MyClient {
                    MyClientProtocolWitness(
                        _someLetProperty: someLetProperty
                    )
                }

                func makingProtocolWitness() async -> MyClientProtocolWitness {
                    await MyClientProtocolWitness(
                        _someLetProperty: someLetProperty
                    )
                }
            }
            """
        }
    }
}

// MARK: Throws

extension ProtocolWitnessingTests {
    func testMacro_createsUnderscoredVariable_andWrapsItWithGetOnlyVar_whenGetOnlyProperty_andThrows() throws {
        assertMacro {
            """
            @ProtocolWitnessing
            protocol MyClient {
                var someLetProperty: Int { get throws }
            }
            """
        } expansion: {
            """
            protocol MyClient {
                var someLetProperty: Int { get throws }
            }

            struct MyClientProtocolWitness: MyClient {
                var someLetProperty: Int {
                    get throws {
                        try _someLetProperty()
                    }
                }
            
                var _someLetProperty: () throws -> Int
            }

            extension MyClient {
                static func makeErasedProtocolWitness(
                    someLetProperty: @escaping () throws -> Int
                ) -> MyClient {
                    MyClientProtocolWitness(
                        _someLetProperty: someLetProperty
                    )
                }
            
                func makingProtocolWitness() throws -> MyClientProtocolWitness {
                    MyClientProtocolWitness(
                        _someLetProperty: {
                            try someLetProperty
                        }
                    )
                }
            }
            """
        }
    }
}

// MARK: Multiple macros

extension ProtocolWitnessingTests {
    func testMacro_addsAttribute_whenExtraAttributesAreAttached() throws {
        assertMacro {
            """
            @SomeAttribute
            @ProtocolWitnessing
            protocol MyClient {
            }
            """
        } expansion: {
            """
            @SomeAttribute
            protocol MyClient {
            }

            struct MyClientProtocolWitness: MyClient {
            }

            extension MyClient {
                static func makeErasedProtocolWitness() -> MyClient {
                    MyClientProtocolWitness()
                }

                func makingProtocolWitness() -> MyClientProtocolWitness {
                    MyClientProtocolWitness()
                }
            }
            """
        }
    }
}

//// MARK: Macro killers 🔫
//
//extension ProtocolWitnessingTests {
//    func testMacro_expandsCorrectly_whenAddingAllTheThings() throws {
//        assertMacro {
//            #"""
//            @MainActor
//            class Thing {
//                func doStuffHere() {
//                    print("Updating UI")
//                }
//            }
//            
//            @ProtocolWitnessing(typeName: "MyClientWitness")
//            @MainActor
//            struct MyClient {
//                let id = "some_id"
//                var myThing: String
//                let yourName: String
//                
//                var one: Int = 1
//                
//                var two: Int = {
//                    2
//                }()
//                
//                static var strings: [String] = [
//                    "a", "b", "c"
//                ]
//                
//                lazy var moreStrings: [String] = {
//                    [
//                        "x", "y", "z"
//                    ]
//                }()
//                
//                func returnsTrue() -> Bool {
//                    true
//                }
//                
//                func returnsVoid() async {
//                    print("doing async stuff for \(yourName)....")
//                    try? await Task.sleep(nanoseconds: 2_000_000_000)
//                    print("async stuff done")
//                }
//                
//                func returnsAThing() async throws -> Thing {
//                    throw MyError.networkIssue
//                }
//                
//                func fetchData(completionHandler: (Int) throws -> Void) rethrows {
//                    try completionHandler(10)
//                }
//                
//                enum MyError: Error { case networkIssue }
//            }
//            
//            extension MyClient {
//                func doSomethingElse() {
//                    // This function won't be seen by the macro declared on the original struct
//                }
//            }
//            """#
//        } expansion: {
//            #"""
//            @MainActor
//            class Thing {
//                func doStuffHere() {
//                    print("Updating UI")
//                }
//            }
//            @MainActor
//            struct MyClient {
//                let id = "some_id"
//                var myThing: String
//                let yourName: String
//                
//                var one: Int = 1
//                
//                var two: Int = {
//                    2
//                }()
//                
//                static var strings: [String] = [
//                    "a", "b", "c"
//                ]
//                
//                lazy var moreStrings: [String] = {
//                    [
//                        "x", "y", "z"
//                    ]
//                }()
//                
//                func returnsTrue() -> Bool {
//                    true
//                }
//                
//                func returnsVoid() async {
//                    print("doing async stuff for \(yourName)....")
//                    try? await Task.sleep(nanoseconds: 2_000_000_000)
//                    print("async stuff done")
//                }
//                
//                func returnsAThing() async throws -> Thing {
//                    throw MyError.networkIssue
//                }
//                
//                func fetchData(completionHandler: (Int) throws -> Void) rethrows {
//                    try completionHandler(10)
//                }
//                
//                enum MyError: Error { case networkIssue }
//
//                struct MyClientWitness {
//                    var myThing: String {
//                        get {
//                            _myThing
//                        }
//                    }
//
//                    var _myThing: String
//
//                    var yourName: String {
//                        get {
//                            _yourName
//                        }
//                    }
//
//                    var _yourName: String
//
//                    var one: Int = 1
//
//                    var two: Int = {
//                            2
//                        }()
//
//                    static var strings: [String] = [
//                            "a", "b", "c"
//                        ]
//
//                    lazy var moreStrings: [String] = {
//                            [
//                                "x", "y", "z"
//                            ]
//                        }()
//
//                    var _returnsTrue: () -> Bool
//
//                    var _returnsVoid: () async -> Void
//
//                    var _returnsAThing: () async throws -> Thing
//
//                    var _fetchData: ((Int) throws -> Void) throws -> Void
//
//                    init(
//                        myThing: String,
//                        yourName: String,
//                        returnsTrue: @escaping () -> Bool,
//                        returnsVoid: @escaping () async -> Void,
//                        returnsAThing: @escaping () async throws -> Thing,
//                        fetchData: @escaping ((Int) throws -> Void) throws -> Void
//                    ) {
//                        _myThing = myThing
//                        _yourName = yourName
//                        _returnsTrue = returnsTrue
//                        _returnsVoid = returnsVoid
//                        _returnsAThing = returnsAThing
//                        _fetchData = fetchData
//                    }
//
//                    func returnsTrue() -> Bool {
//                        _returnsTrue()
//                    }
//
//                    func returnsVoid() async {
//                        await _returnsVoid()
//                    }
//
//                    func returnsAThing() async throws -> Thing {
//                        try await _returnsAThing()
//                    }
//
//                    func fetchData(completionHandler: (Int) throws -> Void) throws {
//                        try _fetchData(completionHandler)
//                    }
//
//                    private static var _production: MyClient?
//
//                    @MainActor
//                    static func production(
//                        myThing: String,
//                        yourName: String
//                    ) -> MyClient.MyClientWitness {
//                        let production = _production ?? MyClient(
//                            myThing: myThing,
//                            yourName: yourName
//                        )
//
//                        if _production == nil {
//                            _production = production
//                        }
//
//                        return MyClient.MyClientWitness(
//                            myThing: production.myThing,
//                            yourName: production.yourName,
//                            returnsTrue: production.returnsTrue,
//                            returnsVoid: production.returnsVoid,
//                            returnsAThing: production.returnsAThing,
//                            fetchData: production.fetchData
//                        )
//                    }
//                }
//            }
//
//            extension MyClient {
//                func doSomethingElse() {
//                    // This function won't be seen by the macro declared on the original struct
//                }
//            }
//            """#
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
