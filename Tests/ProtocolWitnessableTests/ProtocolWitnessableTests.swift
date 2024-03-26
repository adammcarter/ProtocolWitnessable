import MacroTesting
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(ProtocolWitnessableMacros)
import ProtocolWitnessableMacros

final class ProtocolWitnessableTests: XCTestCase {
    override func invokeTest() {
//        withMacroTesting(isRecording: true, macros: [
        withMacroTesting(macros: [
            "ProtocolWitnessable": ProtocolWitnessableMacro.self,
        ]) {
            super.invokeTest()
        }
    }
}

/*
 TODO: Updates
 - Add extension (https://forums.swift.org/t/circular-reference-when-combining-attached-peer-and-extension-macros/70901):
     extension MyClient {
        typealias ProtocolWitness = MyClientProtocolWitness
     }
 - Make class a final class in implementation
    - Feels like we never want the classes to be subclasses but do final classes still allow extensions? Double check.
 - Do we need to add any specific stuff in the witness when the protocol is marked as MainActor?
 - Use nicer syntax for creating/manipulating types like here:
    https://forums.swift.org/t/workaround-for-macros-not-allowed-to-add-extensions/67916/2
 - Rename makeErasedProtocolWitness() -> makingErased()
 - make statis preview() func with default args
    - default args including closures with args inside them
    - use autoclosure where possible?
 - make static test() like above
 - update isObservable to extendable array of extra attributes
 
 - Add support for attaching to actors?
 - Use SwiftSyntaxMacros builders?

 - Create an inversed version of this
 - @InversedProtocolWitness
 - Turns a concrete type in to a protocol witness protocol then expands that in to a protocol witness, adopting the target to the protocol too
 For example. Apple's UserDefaults is already implemented so it would be good to avoid the overweight task of turning that in to a protocol then re-implementing it in to structs.
 
 
 - Enable concurrency checking to "complete" mode - https://forums.swift.org/t/concurrency-checking-in-swift-packages-unsafeflags/61135
 - Use Swift Testing instead of XCTest
 - Refactor all the stuff
 
 
 TODO: When done
 - Write documentation in code/docc and GitHub readme
 - Post about it in https://forums.swift.org/c/community-showcase/66
 - Add to the SPM index

 */

// MARK: - Attachment checking

extension ProtocolWitnessableTests {
    func testMacro_throwsError_whenAttachedToStruct() throws {
        assertMacro {
            """
            @ProtocolWitnessable
            struct MyClient { }
            """
        } diagnostics: {
            """
            @ProtocolWitnessable
            ┬───────────────────
            ╰─ 🛑 @ProtocolWitnessable can only be attached to protocols
            struct MyClient { }
            """
        }
    }
    
    func testMacro_throwsError_whenAttachedToClass() throws {
        assertMacro {
            """
            @ProtocolWitnessable
            class MyClient { }
            """
        } diagnostics: {
            """
            @ProtocolWitnessable
            ┬───────────────────
            ╰─ 🛑 @ProtocolWitnessable can only be attached to protocols
            class MyClient { }
            """
        }
    }
    
    func testMacro_throwsError_whenAttachedToActor() throws {
        assertMacro {
            """
            @ProtocolWitnessable
            actor MyClient { }
            """
        } diagnostics: {
            """
            @ProtocolWitnessable
            ┬───────────────────
            ╰─ 🛑 @ProtocolWitnessable can only be attached to protocols
            actor MyClient { }
            """
        }
    }
    
    func testMacro_throwsError_whenAttachedToEnum() throws {
        assertMacro {
            """
            @ProtocolWitnessable
            enum MyClient { }
            """
        } diagnostics: {
            """
            @ProtocolWitnessable
            ┬───────────────────
            ╰─ 🛑 @ProtocolWitnessable can only be attached to protocols
            enum MyClient { }
            """
        }
    }
}

// MARK: - targetType argument

extension ProtocolWitnessableTests {
    func testMacro_usesStructTypeByDefault() throws {
        assertMacro {
            """
            @ProtocolWitnessable()
            protocol MyClient { }
            """
        } expansion: {
            """
            protocol MyClient { }

            struct MyClientProtocolWitness: MyClient {
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
    
    func testMacro_usesStructType_whenTargetTypeIsStruct() throws {
        assertMacro {
            """
            @ProtocolWitnessable(targetType: .struct)
            protocol MyClient { }
            """
        } expansion: {
            """
            protocol MyClient { }

            struct MyClientProtocolWitness: MyClient {
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
    
    func testMacro_usesClassType_andCreatesInit_whenTargetTypeIsClass() throws {
        assertMacro {
            """
            @ProtocolWitnessable(targetType: .class)
            protocol MyClient { }
            """
        } expansion: {
            """
            protocol MyClient { }

            class MyClientProtocolWitness: MyClient {
                static func makeErasedProtocolWitness() -> MyClient {
                    MyClientProtocolWitness()
                }

                func makingProtocolWitness() -> MyClientProtocolWitness {
                    MyClientProtocolWitness()
                }
            
                init() {
                }
            }
            """
        }
    }
    
    func testMacro_usesClassType_andCreatesInitWithParameters_whenTargetTypeIsClass() throws {
        assertMacro {
            """
            @ProtocolWitnessable(targetType: .class)
            protocol MyClient {
                var someString: String { get }
            }
            """
        } expansion: {
            """
            protocol MyClient {
                var someString: String { get }
            }

            class MyClientProtocolWitness: MyClient {
                var someString: String {
                    _someString
                }

                var _someString: String

                static func makeErasedProtocolWitness(
                    someString: String
                ) -> MyClient {
                    MyClientProtocolWitness(
                        _someString: someString
                    )
                }

                func makingProtocolWitness() -> MyClientProtocolWitness {
                    MyClientProtocolWitness(
                        _someString: someString
                    )
                }

                init(
                    _someString: String
                ) {
                    self._someString = _someString
                }
            }
            """
        }
    }
    
    func testMacro_usesClassType_andCreatesInitWithParameters_whenTargetTypeIsClass_andMultipleProperties_andGetOnly() throws {
        assertMacro {
            """
            @ProtocolWitnessable(targetType: .class)
            protocol MyClient {
                var someString: String { get }
                var anotherString: String { get }
            }
            """
        } expansion: {
            """
            protocol MyClient {
                var someString: String { get }
                var anotherString: String { get }
            }

            class MyClientProtocolWitness: MyClient {
                var someString: String {
                    _someString
                }

                var _someString: String

                var anotherString: String {
                    _anotherString
                }

                var _anotherString: String

                static func makeErasedProtocolWitness(
                    someString: String,
                    anotherString: String
                ) -> MyClient {
                    MyClientProtocolWitness(
                        _someString: someString,
                        _anotherString: anotherString
                    )
                }

                func makingProtocolWitness() -> MyClientProtocolWitness {
                    MyClientProtocolWitness(
                        _someString: someString,
                        _anotherString: anotherString
                    )
                }

                init(
                    _someString: String,
                    _anotherString: String
                ) {
                    self._someString = _someString
                    self._anotherString = _anotherString
                }
            }
            """
        }
    }
    
    func testMacro_usesClassType_andCreatesInitWithParameters_whenTargetTypeIsClass_andMultipleProperties_andGetSet() throws {
        assertMacro {
            """
            @ProtocolWitnessable(targetType: .class)
            protocol MyClient {
                var someString: String { get set }
                var anotherString: String { get set }
            }
            """
        } expansion: {
            """
            protocol MyClient {
                var someString: String { get set }
                var anotherString: String { get set }
            }

            class MyClientProtocolWitness: MyClient {
                var someString: String

                var anotherString: String

                static func makeErasedProtocolWitness(
                    someString: String,
                    anotherString: String
                ) -> MyClient {
                    MyClientProtocolWitness(
                        someString: someString,
                        anotherString: anotherString
                    )
                }

                func makingProtocolWitness() -> MyClientProtocolWitness {
                    MyClientProtocolWitness(
                        someString: someString,
                        anotherString: anotherString
                    )
                }

                init(
                    someString: String,
                    anotherString: String
                ) {
                    self.someString = someString
                    self.anotherString = anotherString
                }
            }
            """
        }
    }
    
    // TODO: Class tests for other things like throws/async etc.
}

// MARK: - isObservable argument

extension ProtocolWitnessableTests {
    func testMacro_doesNotAddObservableByDefault() throws {
        assertMacro {
            """
            @ProtocolWitnessable()
            protocol MyClient { }
            """
        } expansion: {
            """
            protocol MyClient { }

            struct MyClientProtocolWitness: MyClient {
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
    
    func testMacro_usesMainActor_whenIsObservableIsFalse() throws {
        assertMacro {
            """
            @ProtocolWitnessable(isObservable: false)
            protocol MyClient { }
            """
        } expansion: {
            """
            protocol MyClient { }
            
            struct MyClientProtocolWitness: MyClient {
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
    
    func testMacro_usesMainActor_whenIsObservableIsTrue() throws {
        assertMacro {
            """
            @ProtocolWitnessable(isObservable: true)
            protocol MyClient { }
            """
        } expansion: {
            """
            protocol MyClient { }

            @Observable
            struct MyClientProtocolWitness: MyClient {
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

// MARK: - Multiple arguments

extension ProtocolWitnessableTests {
    func testMacro_usesClassAndObservable_whenArguments() throws {
        assertMacro {
            """
            @ProtocolWitnessable(targetType: .class, isObservable: true)
            protocol MyClient { }
            """
        } expansion: {
            """
            protocol MyClient { }
            
            @Observable
            class MyClientProtocolWitness: MyClient {
                static func makeErasedProtocolWitness() -> MyClient {
                    MyClientProtocolWitness()
                }
            
                func makingProtocolWitness() -> MyClientProtocolWitness {
                    MyClientProtocolWitness()
                }
            
                init() {
                }
            }
            """
        }
    }
    
    func testMacro_usesClass_butNotObservable_whenArguments() throws {
        assertMacro {
            """
            @ProtocolWitnessable(targetType: .class, isObservable: false)
            protocol MyClient { }
            """
        } expansion: {
            """
            protocol MyClient { }
            
            class MyClientProtocolWitness: MyClient {
                static func makeErasedProtocolWitness() -> MyClient {
                    MyClientProtocolWitness()
                }
            
                func makingProtocolWitness() -> MyClientProtocolWitness {
                    MyClientProtocolWitness()
                }
            
                init() {
                }
            }
            """
        }
    }
}

// MARK: - Empty structure

extension ProtocolWitnessableTests {
    func testMacro_createsEmptyStruct_andEmptyExtensionOnProtocol_whenProtocolIsEmpty_andProtocolIsImplicitlyInternal() throws {
        assertMacro {
            """
            @ProtocolWitnessable
            protocol MyClient { }
            """
        } expansion: {
            """
            protocol MyClient { }

            struct MyClientProtocolWitness: MyClient {
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
            @ProtocolWitnessable
            internal protocol MyClient { }
            """
        } expansion: {
            """
            internal protocol MyClient { }

            internal struct MyClientProtocolWitness: MyClient {
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
            @ProtocolWitnessable
            public protocol MyClient { }
            """
        } expansion: {
            """
            public protocol MyClient { }

            public struct MyClientProtocolWitness: MyClient {
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
            @ProtocolWitnessable
            private protocol MyClient { }
            """
        } expansion: {
            """
            private protocol MyClient { }

            private struct MyClientProtocolWitness: MyClient {
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
            @ProtocolWitnessable
            fileprivate protocol MyClient { }
            """
        } expansion: {
            """
            fileprivate protocol MyClient { }

            fileprivate struct MyClientProtocolWitness: MyClient {
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

extension ProtocolWitnessableTests {
    func testMacro_addsWrappedFunction_andProperty_andInitializerParameters_whenOneFunction_andInstanceFunc_andNoArguments_andImplicitlyReturnsVoid_andImplicitlyInternal() throws {
        assertMacro {
            """
            @ProtocolWitnessable
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
            @ProtocolWitnessable
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
            @ProtocolWitnessable
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
            @ProtocolWitnessable
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
            @ProtocolWitnessable
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
            @ProtocolWitnessable
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
            @ProtocolWitnessable
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
            @ProtocolWitnessable
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

extension ProtocolWitnessableTests {
    func testMacro_addsWrappedFunction_andProperty_andInitializerParameters_whenTwoFunctions_andInstanceFunc_andNoArguments_andImplicitlyReturnsVoid_andImplicitlyInternal() throws {
        assertMacro {
            """
            @ProtocolWitnessable
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
            @ProtocolWitnessable
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
            @ProtocolWitnessable
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
            @ProtocolWitnessable
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
            @ProtocolWitnessable
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
            @ProtocolWitnessable
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

// MARK: Unnamed parameters

extension ProtocolWitnessableTests {
    func testMacro_whenFunctionHasOneUnnamedParameter() throws {
        assertMacro {
            """
            @ProtocolWitnessable
            protocol MyClient {
                func doSomething(_ hiddenName: String)
            }
            """
        } expansion: {
            """
            protocol MyClient {
                func doSomething(_ hiddenName: String)
            }

            struct MyClientProtocolWitness: MyClient {
                func doSomething(_ hiddenName: String) {
                    _doSomething(hiddenName)
                }

                var _doSomething: (String) -> Void

                static func makeErasedProtocolWitness(
                    doSomething: @escaping (String) -> Void
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
    
    func testMacro_whenFunctionHasMultipleUnnamedParameters() throws {
        assertMacro {
            """
            @ProtocolWitnessable
            protocol MyClient {
                func doSomething(_ hiddenName: String, _ anotherUnnamed: Int)
            }
            """
        } expansion: {
            """
            protocol MyClient {
                func doSomething(_ hiddenName: String, _ anotherUnnamed: Int)
            }

            struct MyClientProtocolWitness: MyClient {
                func doSomething(_ hiddenName: String, _ anotherUnnamed: Int) {
                    _doSomething(hiddenName, anotherUnnamed)
                }

                var _doSomething: (String, Int) -> Void

                static func makeErasedProtocolWitness(
                    doSomething: @escaping (String, Int) -> Void
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

// MARK: Attributes

extension ProtocolWitnessableTests {
    func testMacro_whenFunctionHasNoAttributes() throws {
        assertMacro {
            """
            @ProtocolWitnessable
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
    
    func testMacro_whenFunctionHasOneAttribute() throws {
        assertMacro {
            """
            @ProtocolWitnessable
            protocol MyClient {
                @discardableResult
                func doSomething() -> Int
            }
            """
        } expansion: {
            """
            protocol MyClient {
                @discardableResult
                func doSomething() -> Int
            }

            struct MyClientProtocolWitness: MyClient {
                @discardableResult
                func doSomething() -> Int {
                    _doSomething()
                }

                var _doSomething: () -> Int

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
    
    func testMacro_whenFunctionTwoAttributes() throws {
        assertMacro {
            """
            @ProtocolWitnessable
            protocol MyClient {
                @available(iOS 16, *)
                @discardableResult
                func doSomethingForiOS16() -> Int
            }
            """
        } expansion: {
            """
            protocol MyClient {
                @available(iOS 16, *)
                @discardableResult
                func doSomethingForiOS16() -> Int
            }

            struct MyClientProtocolWitness: MyClient {
                @available(iOS 16, *)
                @discardableResult
                func doSomethingForiOS16() -> Int {
                    _doSomethingForiOS16()
                }

                var _doSomethingForiOS16: () -> Int

                static func makeErasedProtocolWitness(
                    doSomethingForiOS16: @escaping () -> Int
                ) -> MyClient {
                    MyClientProtocolWitness(
                        _doSomethingForiOS16: doSomethingForiOS16
                    )
                }

                func makingProtocolWitness() -> MyClientProtocolWitness {
                    MyClientProtocolWitness(
                        _doSomethingForiOS16: doSomethingForiOS16
                    )
                }
            }
            """
        }
    }
}

// MARK: Async/await

extension ProtocolWitnessableTests {
    func testMacro_whenOneFunction_andFunctionIsAsync() throws {
        assertMacro {
            """
            @ProtocolWitnessable
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
            @ProtocolWitnessable
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
            @ProtocolWitnessable
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
    
    func testMacro_whenOneFunction_andFunctionIsAsync_andHasReturnValue() throws {
        assertMacro {
            """
            @ProtocolWitnessable
            protocol MyClient {
                func doSomething(withStrings: [String]) async -> [String]
            }
            """
        } expansion: {
            """
            protocol MyClient {
                func doSomething(withStrings: [String]) async -> [String]
            }

            struct MyClientProtocolWitness: MyClient {
                func doSomething(withStrings: [String]) async -> [String] {
                    await _doSomething(withStrings)
                }

                var _doSomething: ([String]) async -> [String]

                static func makeErasedProtocolWitness(
                    doSomething: @escaping ([String]) async -> [String]
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

// MARK: Throwing

extension ProtocolWitnessableTests {
    func testMacro_whenOneFunction_andFunctionIsThrowing() throws {
        assertMacro {
            """
            @ProtocolWitnessable
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
            @ProtocolWitnessable
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
            @ProtocolWitnessable
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

extension ProtocolWitnessableTests {
    func testMacro_whenFunctionParametersContainsVoidToVoidClosure() throws {
        assertMacro {
            """
            @ProtocolWitnessable
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
            @ProtocolWitnessable
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
            @ProtocolWitnessable
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
            @ProtocolWitnessable
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
            @ProtocolWitnessable
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
            @ProtocolWitnessable
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
            @ProtocolWitnessable
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
            @ProtocolWitnessable
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
            @ProtocolWitnessable
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

extension ProtocolWitnessableTests {
    func testMacro_expandsType_whenContainingFunction_andProtocolHasLotsOfWhitespaceAroundName() throws {
        assertMacro {
            """
            @ProtocolWitnessable
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
                func doSomething() ->   Void {
                    _doSomething()
                }

                var _doSomething: () ->   Void

                static func makeErasedProtocolWitness(
                    doSomething: @escaping () ->   Void
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
            @ProtocolWitnessable
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
                func doSomething() ->   Void {
                    _doSomething()
                }

                var _doSomething: () ->   Void

                static func makeErasedProtocolWitness(
                    doSomething: @escaping () ->   Void
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
            @ProtocolWitnessable
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
            @ProtocolWitnessable
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

extension ProtocolWitnessableTests {
    func testMacro_createsUnderscoredVariable_andWrapsItWithGetOnlyVar_whenGetOnlyProperty() throws {
        assertMacro {
            """
            @ProtocolWitnessable
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
            @ProtocolWitnessable
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
            @ProtocolWitnessable
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
            @ProtocolWitnessable
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
            @ProtocolWitnessable
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
            @ProtocolWitnessable
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
            @ProtocolWitnessable
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
            @ProtocolWitnessable
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

extension ProtocolWitnessableTests {
    func testMacro_createsUnderscoredVariable_andWrapsItWithGetOnlyVar_whenGetOnlyProperty_andAsync() throws {
        assertMacro {
            """
            @ProtocolWitnessable
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
            @ProtocolWitnessable
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

extension ProtocolWitnessableTests {
    func testMacro_createsUnderscoredVariable_andWrapsItWithGetOnlyVar_whenGetOnlyProperty_andThrows() throws {
        assertMacro {
            """
            @ProtocolWitnessable
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

// MARK: - Macros

extension ProtocolWitnessableTests {
    func testMacro_addsAttribute_whenExtraAttributesAreAttached() throws {
        assertMacro {
            """
            @SomeAttribute
            @ProtocolWitnessable
            protocol MyClient {
            }
            """
        } expansion: {
            """
            @SomeAttribute
            protocol MyClient {
            }

            struct MyClientProtocolWitness: MyClient {
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
    
    func testMacro_addsAttribute_whenExtraAttributesIsMainActor() throws {
        assertMacro {
            """
            @MainActor
            @ProtocolWitnessable
            protocol MyClient {
                var someProperty: Int { get }
            
                @MainActor
                func doSomething()
            }
            """
        } expansion: {
            """
            @MainActor
            protocol MyClient {
                var someProperty: Int { get }

                @MainActor
                func doSomething()
            }

            struct MyClientProtocolWitness: MyClient {
                var someProperty: Int {
                    _someProperty
                }

                var _someProperty: Int

                @MainActor
                func doSomething() {
                    _doSomething()
                }

                var _doSomething: () -> Void

                static func makeErasedProtocolWitness(
                    someProperty: Int,
                    doSomething: @escaping () -> Void
                ) -> MyClient {
                    MyClientProtocolWitness(
                        _someProperty: someProperty,
                        _doSomething: doSomething
                    )
                }

                func makingProtocolWitness() -> MyClientProtocolWitness {
                    MyClientProtocolWitness(
                        _someProperty: someProperty,
                        _doSomething: doSomething
                    )
                }
            }
            """
        }
    }
}
#else
final class ProtocolWitnessableTests: XCTestCase {
    func testMacro() throws {
        throw XCTSkip("macros are only supported when running tests for the host platform")
    }
}
#endif
