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

//// MARK: - Functions
//
//// MARK: One
//
//extension ProtocolWitnessingTests {
//    func testMacro_addsInitWithVoidToVoidClosure_andPropertyForVoidToVoidClosure_whenOneFunction_andNoArguments_andReturnsVoid() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing
//            struct MyClient {
//                func doSomething() { }
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//                func doSomething() { }
//            
//                struct ProtocolWitness {
//                    var _doSomething: () -> Void
//            
//                    init(doSomething: @escaping () -> Void) {
//                        _doSomething = doSomething
//                    }
//            
//                    func doSomething() {
//                        _doSomething()
//                    }
//            
//                    private static var _production: MyClient?
//            
//                    static func production() -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient()
//            
//                        if _production == nil {
//                            _production = production
//                        }
//            
//                        return MyClient.ProtocolWitness(
//                            doSomething: production.doSomething
//                        )
//                    }
//                }
//            }
//            """
//        }
//    }
//    
//    func testMacro_addsInitWithParameterToVoidClosure_andPropertyForParameterToVoidClosure_whenOneFunction_andOneArgument_andReturnsVoid() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing
//            struct MyClient {
//                func doSomething(int: Int) { }
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//                func doSomething(int: Int) { }
//            
//                struct ProtocolWitness {
//                    var _doSomething: (Int) -> Void
//            
//                    init(doSomething: @escaping (Int) -> Void) {
//                        _doSomething = doSomething
//                    }
//            
//                    func doSomething(int: Int) {
//                        _doSomething(int)
//                    }
//            
//                    private static var _production: MyClient?
//            
//                    static func production() -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient()
//            
//                        if _production == nil {
//                            _production = production
//                        }
//            
//                        return MyClient.ProtocolWitness(
//                            doSomething: production.doSomething
//                        )
//                    }
//                }
//            }
//            """
//        }
//    }
//    
//    func testMacro_addsInitWithParameterToReturnValueClosure_andPropertyForParameterToReturnValueClosure_whenOneFunction_andOneArgument_andReturnValue() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing
//            struct MyClient {
//                func doSomething(int: Int) -> Double { 0.5 }
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//                func doSomething(int: Int) -> Double { 0.5 }
//            
//                struct ProtocolWitness {
//                    var _doSomething: (Int) -> Double
//            
//                    init(doSomething: @escaping (Int) -> Double) {
//                        _doSomething = doSomething
//                    }
//            
//                    func doSomething(int: Int) -> Double {
//                        _doSomething(int)
//                    }
//            
//                    private static var _production: MyClient?
//            
//                    static func production() -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient()
//            
//                        if _production == nil {
//                            _production = production
//                        }
//            
//                        return MyClient.ProtocolWitness(
//                            doSomething: production.doSomething
//                        )
//                    }
//                }
//            }
//            """
//        }
//    }
//    
//    func testMacro_addsInitWithParametersToReturnValueClosure_andPropertyForParameterToReturnValueClosure_whenOneFunction_andTwoArguments_andReturnValue() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing
//            struct MyClient {
//                func doSomething(int: Int, float: Float) -> Double { 0.5 }
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//                func doSomething(int: Int, float: Float) -> Double { 0.5 }
//            
//                struct ProtocolWitness {
//                    var _doSomething: (Int, Float) -> Double
//            
//                    init(doSomething: @escaping (Int, Float) -> Double) {
//                        _doSomething = doSomething
//                    }
//            
//                    func doSomething(int: Int, float: Float) -> Double {
//                        _doSomething(int, float)
//                    }
//            
//                    private static var _production: MyClient?
//            
//                    static func production() -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient()
//            
//                        if _production == nil {
//                            _production = production
//                        }
//            
//                        return MyClient.ProtocolWitness(
//                            doSomething: production.doSomething
//                        )
//                    }
//                }
//            }
//            """
//        }
//    }
//}
//
//// MARK: Two
//
//extension ProtocolWitnessingTests {
//    func testMacro_addsInitWithVoidToVoidClosure_andPropertyForVoidToVoidClosure_whenTwoFunctions_andBothHaveNoArguments_andBothReturnsVoid() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing
//            struct MyClient {
//                func doSomething() { }
//                func doAnotherThing() { }
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//                func doSomething() { }
//                func doAnotherThing() { }
//            
//                struct ProtocolWitness {
//                    var _doSomething: () -> Void
//            
//                    var _doAnotherThing: () -> Void
//            
//                    init(
//                        doSomething: @escaping () -> Void,
//                        doAnotherThing: @escaping () -> Void
//                    ) {
//                        _doSomething = doSomething
//                        _doAnotherThing = doAnotherThing
//                    }
//            
//                    func doSomething() {
//                        _doSomething()
//                    }
//            
//                    func doAnotherThing() {
//                        _doAnotherThing()
//                    }
//            
//                    private static var _production: MyClient?
//            
//                    static func production() -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient()
//            
//                        if _production == nil {
//                            _production = production
//                        }
//            
//                        return MyClient.ProtocolWitness(
//                            doSomething: production.doSomething,
//                            doAnotherThing: production.doAnotherThing
//                        )
//                    }
//                }
//            }
//            """
//        }
//    }
//    
//    func testMacro_addsInitWithParameterToVoidClosure_andPropertyForParameterToVoidClosure_whenTwoFunctions_andBothHaveOneArgument_andBothReturnsVoid() throws {
//        assertMacro {
//            """
//            enum MyType {}
//            enum OtherType {}
//            
//            @ProtocolWitnessing
//            struct MyClient {
//                func doSomething(arg1: MyType) { }
//                func doAnotherThing(otherArg: OtherType) { }
//            }
//            """
//        } expansion: {
//            """
//            enum MyType {}
//            enum OtherType {}
//            struct MyClient {
//                func doSomething(arg1: MyType) { }
//                func doAnotherThing(otherArg: OtherType) { }
//            
//                struct ProtocolWitness {
//                    var _doSomething: (MyType) -> Void
//            
//                    var _doAnotherThing: (OtherType) -> Void
//            
//                    init(
//                        doSomething: @escaping (MyType) -> Void,
//                        doAnotherThing: @escaping (OtherType) -> Void
//                    ) {
//                        _doSomething = doSomething
//                        _doAnotherThing = doAnotherThing
//                    }
//            
//                    func doSomething(arg1: MyType) {
//                        _doSomething(arg1)
//                    }
//            
//                    func doAnotherThing(otherArg: OtherType) {
//                        _doAnotherThing(otherArg)
//                    }
//            
//                    private static var _production: MyClient?
//            
//                    static func production() -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient()
//            
//                        if _production == nil {
//                            _production = production
//                        }
//            
//                        return MyClient.ProtocolWitness(
//                            doSomething: production.doSomething,
//                            doAnotherThing: production.doAnotherThing
//                        )
//                    }
//                }
//            }
//            """
//        }
//    }
//    
//    func testMacro_addsInitWithParameterToReturnValueClosure_andPropertyForParameterToReturnValueClosure_whenTwoFunctions_andBothHaveOneArgument_andBothReturnValues() throws {
//        assertMacro {
//            """
//            enum MyType {}
//            enum OtherType {}
//            
//            @ProtocolWitnessing
//            struct MyClient {
//                func doSomething(arg1: MyType) -> OtherType { }
//                func doAnotherThing(otherArg: OtherType) -> MyType { }
//            }
//            """
//        } expansion: {
//            """
//            enum MyType {}
//            enum OtherType {}
//            struct MyClient {
//                func doSomething(arg1: MyType) -> OtherType { }
//                func doAnotherThing(otherArg: OtherType) -> MyType { }
//            
//                struct ProtocolWitness {
//                    var _doSomething: (MyType) -> OtherType
//            
//                    var _doAnotherThing: (OtherType) -> MyType
//            
//                    init(
//                        doSomething: @escaping (MyType) -> OtherType,
//                        doAnotherThing: @escaping (OtherType) -> MyType
//                    ) {
//                        _doSomething = doSomething
//                        _doAnotherThing = doAnotherThing
//                    }
//            
//                    func doSomething(arg1: MyType) -> OtherType {
//                        _doSomething(arg1)
//                    }
//            
//                    func doAnotherThing(otherArg: OtherType) -> MyType {
//                        _doAnotherThing(otherArg)
//                    }
//            
//                    private static var _production: MyClient?
//            
//                    static func production() -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient()
//            
//                        if _production == nil {
//                            _production = production
//                        }
//            
//                        return MyClient.ProtocolWitness(
//                            doSomething: production.doSomething,
//                            doAnotherThing: production.doAnotherThing
//                        )
//                    }
//                }
//            }
//            """
//        }
//    }
//    
//    func testMacro_addsInitWithParametersToReturnValueClosure_andPropertyForParameterToReturnValueClosure_whenTwoFunctions_andBothHaveTwoArguments_andBothReturnValues() throws {
//        assertMacro {
//            """
//            enum MyType {}
//            enum OtherType {}
//            enum TypeTwo {}
//            enum AnotherType {}
//            
//            @ProtocolWitnessing
//            struct MyClient {
//                func doSomething(arg1: MyType, arg2: TypeTwo) -> OtherType { }
//                func doAnotherThing(otherArg: OtherType, anotherArg: AnotherType) -> MyType { }
//            }
//            """
//        } expansion: {
//            """
//            enum MyType {}
//            enum OtherType {}
//            enum TypeTwo {}
//            enum AnotherType {}
//            struct MyClient {
//                func doSomething(arg1: MyType, arg2: TypeTwo) -> OtherType { }
//                func doAnotherThing(otherArg: OtherType, anotherArg: AnotherType) -> MyType { }
//            
//                struct ProtocolWitness {
//                    var _doSomething: (MyType, TypeTwo) -> OtherType
//            
//                    var _doAnotherThing: (OtherType, AnotherType) -> MyType
//            
//                    init(
//                        doSomething: @escaping (MyType, TypeTwo) -> OtherType,
//                        doAnotherThing: @escaping (OtherType, AnotherType) -> MyType
//                    ) {
//                        _doSomething = doSomething
//                        _doAnotherThing = doAnotherThing
//                    }
//            
//                    func doSomething(arg1: MyType, arg2: TypeTwo) -> OtherType {
//                        _doSomething(arg1, arg2)
//                    }
//            
//                    func doAnotherThing(otherArg: OtherType, anotherArg: AnotherType) -> MyType {
//                        _doAnotherThing(otherArg, anotherArg)
//                    }
//            
//                    private static var _production: MyClient?
//            
//                    static func production() -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient()
//            
//                        if _production == nil {
//                            _production = production
//                        }
//            
//                        return MyClient.ProtocolWitness(
//                            doSomething: production.doSomething,
//                            doAnotherThing: production.doAnotherThing
//                        )
//                    }
//                }
//            }
//            """
//        }
//    }
//}
//
//// MARK: Private
//
//extension ProtocolWitnessingTests {
//    func testMacro_doesNotIncludePrivateFunction_whenOnlyPrivateFunction() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing
//            struct MyClient {
//                private func doSomething() { }
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//                private func doSomething() { }
//            
//                struct ProtocolWitness {
//                    init() {
//                    }
//            
//                    private static var _production: MyClient?
//            
//                    static func production() -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient()
//            
//                        if _production == nil {
//                            _production = production
//                        }
//            
//                        return MyClient.ProtocolWitness()
//                    }
//                }
//            }
//            """
//        }
//    }
//    
//    func testMacro_doesNotIncludePrivateFunction_whenMixOfInternalAndPrivateFunctions() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing
//            struct MyClient {
//                func notSecret() { }
//            
//                private func somethingSecret() { }
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//                func notSecret() { }
//            
//                private func somethingSecret() { }
//            
//                struct ProtocolWitness {
//                    var _notSecret: () -> Void
//            
//                    init(notSecret: @escaping () -> Void) {
//                        _notSecret = notSecret
//                    }
//            
//                    func notSecret() {
//                        _notSecret()
//                    }
//            
//                    private static var _production: MyClient?
//            
//                    static func production() -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient()
//            
//                        if _production == nil {
//                            _production = production
//                        }
//            
//                        return MyClient.ProtocolWitness(
//                            notSecret: production.notSecret
//                        )
//                    }
//                }
//            }
//            """
//        }
//    }
//}
//
//// MARK: Internal
//
//extension ProtocolWitnessingTests {
//    func testMacro_includesFunction_whenExplicitlySetAsInternal() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing
//            struct MyClient {
//                internal func doSomething() { }
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//                internal func doSomething() { }
//            
//                struct ProtocolWitness {
//                    internal var _doSomething: () -> Void
//            
//                    init(doSomething: @escaping () -> Void) {
//                        _doSomething = doSomething
//                    }
//            
//                    internal func doSomething() {
//                        _doSomething()
//                    }
//            
//                    private static var _production: MyClient?
//            
//                    static func production() -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient()
//            
//                        if _production == nil {
//                            _production = production
//                        }
//            
//                        return MyClient.ProtocolWitness(
//                            doSomething: production.doSomething
//                        )
//                    }
//                }
//            }
//            """
//        }
//    }
//    
//    func testMacro_includesFunction_whenMix_andOneIsExplicitlySetAsInternal() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing
//            struct MyClient {
//                internal func explicitInternalDoSomething() { }
//            
//                func doSomething() { }
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//                internal func explicitInternalDoSomething() { }
//            
//                func doSomething() { }
//            
//                struct ProtocolWitness {
//                    internal var _explicitInternalDoSomething: () -> Void
//            
//                    var _doSomething: () -> Void
//            
//                    init(
//                        explicitInternalDoSomething: @escaping () -> Void,
//                        doSomething: @escaping () -> Void
//                    ) {
//                        _explicitInternalDoSomething = explicitInternalDoSomething
//                        _doSomething = doSomething
//                    }
//            
//                    internal func explicitInternalDoSomething() {
//                        _explicitInternalDoSomething()
//                    }
//            
//                    func doSomething() {
//                        _doSomething()
//                    }
//            
//                    private static var _production: MyClient?
//            
//                    static func production() -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient()
//            
//                        if _production == nil {
//                            _production = production
//                        }
//            
//                        return MyClient.ProtocolWitness(
//                            explicitInternalDoSomething: production.explicitInternalDoSomething,
//                            doSomething: production.doSomething
//                        )
//                    }
//                }
//            }
//            """
//        }
//    }
//}
//
//// MARK: Public
//
//extension ProtocolWitnessingTests {
//    func testMacro_includesFunction_whenSetAsPublic() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing
//            struct MyClient {
//                public func doSomething() { }
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//                public func doSomething() { }
//            
//                struct ProtocolWitness {
//                    public var _doSomething: () -> Void
//            
//                    init(doSomething: @escaping () -> Void) {
//                        _doSomething = doSomething
//                    }
//            
//                    public func doSomething() {
//                        _doSomething()
//                    }
//            
//                    private static var _production: MyClient?
//            
//                    static func production() -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient()
//            
//                        if _production == nil {
//                            _production = production
//                        }
//            
//                        return MyClient.ProtocolWitness(
//                            doSomething: production.doSomething
//                        )
//                    }
//                }
//            }
//            """
//        }
//    }
//    
//    func testMacro_includesFunction_whenMix_andOneIsSetAsPublic() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing
//            struct MyClient {
//                public func explicitPublicDoSomething() { }
//            
//                func doSomething() { }
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//                public func explicitPublicDoSomething() { }
//            
//                func doSomething() { }
//            
//                struct ProtocolWitness {
//                    public var _explicitPublicDoSomething: () -> Void
//            
//                    var _doSomething: () -> Void
//            
//                    init(
//                        explicitPublicDoSomething: @escaping () -> Void,
//                        doSomething: @escaping () -> Void
//                    ) {
//                        _explicitPublicDoSomething = explicitPublicDoSomething
//                        _doSomething = doSomething
//                    }
//            
//                    public func explicitPublicDoSomething() {
//                        _explicitPublicDoSomething()
//                    }
//            
//                    func doSomething() {
//                        _doSomething()
//                    }
//            
//                    private static var _production: MyClient?
//            
//                    static func production() -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient()
//            
//                        if _production == nil {
//                            _production = production
//                        }
//            
//                        return MyClient.ProtocolWitness(
//                            explicitPublicDoSomething: production.explicitPublicDoSomething,
//                            doSomething: production.doSomething
//                        )
//                    }
//                }
//            }
//            """
//        }
//    }
//}
//
//// MARK: Static
//
//extension ProtocolWitnessingTests {
//    func testMacro_includesFunction_whenStatic() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing
//            struct MyClient {
//                static func doSomething() { }
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//                static func doSomething() { }
//
//                struct ProtocolWitness {
//                    static var _doSomething: () -> Void
//
//                    init() {
//                    }
//
//                    static func doSomething() {
//                        _doSomething()
//                    }
//
//                    private static var _production: MyClient?
//
//                    static func production() -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient()
//
//                        if _production == nil {
//                            _production = production
//                        }
//
//                        return MyClient.ProtocolWitness()
//                    }
//                }
//            }
//            """
//        }
//    }
//    
//    func testMacro_includesFunction_whenStatic_andExplicitAccessor() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing
//            struct MyClient {
//                static func doSomething() { }
//                public static func doSomethingElse() { }
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//                static func doSomething() { }
//                public static func doSomethingElse() { }
//
//                struct ProtocolWitness {
//                    static var _doSomething: () -> Void
//
//                    public static var _doSomethingElse: () -> Void
//
//                    init() {
//                    }
//
//                    static func doSomething() {
//                        _doSomething()
//                    }
//
//                    public static func doSomethingElse() {
//                        _doSomethingElse()
//                    }
//
//                    private static var _production: MyClient?
//
//                    static func production() -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient()
//
//                        if _production == nil {
//                            _production = production
//                        }
//
//                        return MyClient.ProtocolWitness()
//                    }
//                }
//            }
//            """
//        }
//    }
//}
//
//// MARK: Open
//
//extension ProtocolWitnessingTests {
//    func testMacro_includesFunction_whenSetAsOpen() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing
//            struct MyClient {
//                open func doSomething() { }
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//                open func doSomething() { }
//            
//                struct ProtocolWitness {
//                    open var _doSomething: () -> Void
//            
//                    init(doSomething: @escaping () -> Void) {
//                        _doSomething = doSomething
//                    }
//            
//                    open func doSomething() {
//                        _doSomething()
//                    }
//            
//                    private static var _production: MyClient?
//            
//                    static func production() -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient()
//            
//                        if _production == nil {
//                            _production = production
//                        }
//            
//                        return MyClient.ProtocolWitness(
//                            doSomething: production.doSomething
//                        )
//                    }
//                }
//            }
//            """
//        }
//    }
//    
//    func testMacro_includesFunction_whenMix_andOneIsSetAsOpen() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing
//            struct MyClient {
//                open func explicitPublicDoSomething() { }
//            
//                func doSomething() { }
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//                open func explicitPublicDoSomething() { }
//            
//                func doSomething() { }
//            
//                struct ProtocolWitness {
//                    open var _explicitPublicDoSomething: () -> Void
//            
//                    var _doSomething: () -> Void
//            
//                    init(
//                        explicitPublicDoSomething: @escaping () -> Void,
//                        doSomething: @escaping () -> Void
//                    ) {
//                        _explicitPublicDoSomething = explicitPublicDoSomething
//                        _doSomething = doSomething
//                    }
//            
//                    open func explicitPublicDoSomething() {
//                        _explicitPublicDoSomething()
//                    }
//            
//                    func doSomething() {
//                        _doSomething()
//                    }
//            
//                    private static var _production: MyClient?
//            
//                    static func production() -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient()
//            
//                        if _production == nil {
//                            _production = production
//                        }
//            
//                        return MyClient.ProtocolWitness(
//                            explicitPublicDoSomething: production.explicitPublicDoSomething,
//                            doSomething: production.doSomething
//                        )
//                    }
//                }
//            }
//            """
//        }
//    }
//}
//
//// MARK: Async/await
//
//extension ProtocolWitnessingTests {
//    func testMacro_whenOneFunction_andFunctionIsAsync() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing
//            struct MyClient {
//                func doSomething() async { }
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//                func doSomething() async { }
//            
//                struct ProtocolWitness {
//                    var _doSomething: () async -> Void
//            
//                    init(doSomething: @escaping () async -> Void) {
//                        _doSomething = doSomething
//                    }
//            
//                    func doSomething() async {
//                        await _doSomething()
//                    }
//            
//                    private static var _production: MyClient?
//            
//                    static func production() -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient()
//            
//                        if _production == nil {
//                            _production = production
//                        }
//            
//                        return MyClient.ProtocolWitness(
//                            doSomething: production.doSomething
//                        )
//                    }
//                }
//            }
//            """
//        }
//    }
//    
//    func testMacro_whenTwoFunctions_andBothFunctionsAreAsync() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing
//            struct MyClient {
//                func doSomething() async { }
//            
//                func doAnotherThing() async { }
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//                func doSomething() async { }
//            
//                func doAnotherThing() async { }
//            
//                struct ProtocolWitness {
//                    var _doSomething: () async -> Void
//            
//                    var _doAnotherThing: () async -> Void
//            
//                    init(
//                        doSomething: @escaping () async -> Void,
//                        doAnotherThing: @escaping () async -> Void
//                    ) {
//                        _doSomething = doSomething
//                        _doAnotherThing = doAnotherThing
//                    }
//            
//                    func doSomething() async {
//                        await _doSomething()
//                    }
//            
//                    func doAnotherThing() async {
//                        await _doAnotherThing()
//                    }
//            
//                    private static var _production: MyClient?
//            
//                    static func production() -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient()
//            
//                        if _production == nil {
//                            _production = production
//                        }
//            
//                        return MyClient.ProtocolWitness(
//                            doSomething: production.doSomething,
//                            doAnotherThing: production.doAnotherThing
//                        )
//                    }
//                }
//            }
//            """
//        }
//    }
//    
//    func testMacro_whenTwoFunctions_andOnlyOneFunctionsIsAsync() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing
//            struct MyClient {
//                func doSomething() { }
//            
//                func doAnotherThing() async { }
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//                func doSomething() { }
//            
//                func doAnotherThing() async { }
//            
//                struct ProtocolWitness {
//                    var _doSomething: () -> Void
//            
//                    var _doAnotherThing: () async -> Void
//            
//                    init(
//                        doSomething: @escaping () -> Void,
//                        doAnotherThing: @escaping () async -> Void
//                    ) {
//                        _doSomething = doSomething
//                        _doAnotherThing = doAnotherThing
//                    }
//            
//                    func doSomething() {
//                        _doSomething()
//                    }
//            
//                    func doAnotherThing() async {
//                        await _doAnotherThing()
//                    }
//            
//                    private static var _production: MyClient?
//            
//                    static func production() -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient()
//            
//                        if _production == nil {
//                            _production = production
//                        }
//            
//                        return MyClient.ProtocolWitness(
//                            doSomething: production.doSomething,
//                            doAnotherThing: production.doAnotherThing
//                        )
//                    }
//                }
//            }
//            """
//        }
//    }
//}
//
//// MARK: Throwing
//
//extension ProtocolWitnessingTests {
//    func testMacro_whenOneFunction_andFunctionIsThrowing() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing
//            struct MyClient {
//                func doSomething() throws { }
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//                func doSomething() throws { }
//            
//                struct ProtocolWitness {
//                    var _doSomething: () throws -> Void
//            
//                    init(doSomething: @escaping () throws -> Void) {
//                        _doSomething = doSomething
//                    }
//            
//                    func doSomething() throws {
//                        try _doSomething()
//                    }
//            
//                    private static var _production: MyClient?
//            
//                    static func production() -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient()
//            
//                        if _production == nil {
//                            _production = production
//                        }
//            
//                        return MyClient.ProtocolWitness(
//                            doSomething: production.doSomething
//                        )
//                    }
//                }
//            }
//            """
//        }
//    }
//    
//    func testMacro_whenTwoFunctions_andBothFunctionsAreThrowing() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing
//            struct MyClient {
//                func doSomething() throws { }
//            
//                func doSomethingElse() throws { }
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//                func doSomething() throws { }
//            
//                func doSomethingElse() throws { }
//            
//                struct ProtocolWitness {
//                    var _doSomething: () throws -> Void
//            
//                    var _doSomethingElse: () throws -> Void
//            
//                    init(
//                        doSomething: @escaping () throws -> Void,
//                        doSomethingElse: @escaping () throws -> Void
//                    ) {
//                        _doSomething = doSomething
//                        _doSomethingElse = doSomethingElse
//                    }
//            
//                    func doSomething() throws {
//                        try _doSomething()
//                    }
//            
//                    func doSomethingElse() throws {
//                        try _doSomethingElse()
//                    }
//            
//                    private static var _production: MyClient?
//            
//                    static func production() -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient()
//            
//                        if _production == nil {
//                            _production = production
//                        }
//            
//                        return MyClient.ProtocolWitness(
//                            doSomething: production.doSomething,
//                            doSomethingElse: production.doSomethingElse
//                        )
//                    }
//                }
//            }
//            """
//        }
//    }
//    
//    func testMacro_whenTwoFunctions_andOneFunctionIsThrowing_andOtherFunctionIsNot() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing
//            struct MyClient {
//                func doSomething() { }
//            
//                func doSomethingElse() throws { }
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//                func doSomething() { }
//            
//                func doSomethingElse() throws { }
//            
//                struct ProtocolWitness {
//                    var _doSomething: () -> Void
//            
//                    var _doSomethingElse: () throws -> Void
//            
//                    init(
//                        doSomething: @escaping () -> Void,
//                        doSomethingElse: @escaping () throws -> Void
//                    ) {
//                        _doSomething = doSomething
//                        _doSomethingElse = doSomethingElse
//                    }
//            
//                    func doSomething() {
//                        _doSomething()
//                    }
//            
//                    func doSomethingElse() throws {
//                        try _doSomethingElse()
//                    }
//            
//                    private static var _production: MyClient?
//            
//                    static func production() -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient()
//            
//                        if _production == nil {
//                            _production = production
//                        }
//            
//                        return MyClient.ProtocolWitness(
//                            doSomething: production.doSomething,
//                            doSomethingElse: production.doSomethingElse
//                        )
//                    }
//                }
//            }
//            """
//        }
//    }
//}
//
//// MARK: Complex
//
//extension ProtocolWitnessingTests {
//    func testMacro_expandsType_whenFunctionParametersContainsVoidToVoidClosure() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing
//            struct MyClient {
//                func doSomething(completionHandler: (Int) -> Void) {
//                    // Complex logic here...
//                    completionHandler()
//                }
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//                func doSomething(completionHandler: (Int) -> Void) {
//                    // Complex logic here...
//                    completionHandler()
//                }
//            
//                struct ProtocolWitness {
//                    var _doSomething: ((Int) -> Void) -> Void
//            
//                    init(doSomething: @escaping ((Int) -> Void) -> Void) {
//                        _doSomething = doSomething
//                    }
//            
//                    func doSomething(completionHandler: (Int) -> Void) {
//                        _doSomething(completionHandler)
//                    }
//            
//                    private static var _production: MyClient?
//            
//                    static func production() -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient()
//            
//                        if _production == nil {
//                            _production = production
//                        }
//            
//                        return MyClient.ProtocolWitness(
//                            doSomething: production.doSomething
//                        )
//                    }
//                }
//            }
//            """
//        }
//    }
//    
//    func testMacro_expandsType_whenFunctionParametersContainsParamToVoidClosure() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing
//            struct MyClient {
//                func doSomething(completionHandler: (Int) -> Void) {
//                    // Complex logic here...
//                    completionHandler(1234567890)
//                }
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//                func doSomething(completionHandler: (Int) -> Void) {
//                    // Complex logic here...
//                    completionHandler(1234567890)
//                }
//            
//                struct ProtocolWitness {
//                    var _doSomething: ((Int) -> Void) -> Void
//            
//                    init(doSomething: @escaping ((Int) -> Void) -> Void) {
//                        _doSomething = doSomething
//                    }
//            
//                    func doSomething(completionHandler: (Int) -> Void) {
//                        _doSomething(completionHandler)
//                    }
//            
//                    private static var _production: MyClient?
//            
//                    static func production() -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient()
//            
//                        if _production == nil {
//                            _production = production
//                        }
//            
//                        return MyClient.ProtocolWitness(
//                            doSomething: production.doSomething
//                        )
//                    }
//                }
//            }
//            """
//        }
//    }
//    
//    func testMacro_expandsType_whenFunctionParametersContainsVoidToVoidClosure_andClosureIsEscaping() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing
//            struct MyClient {
//                func doSomething(completionHandler: @escaping () -> Void) {
//                    completionHandler()
//                }
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//                func doSomething(completionHandler: @escaping () -> Void) {
//                    completionHandler()
//                }
//            
//                struct ProtocolWitness {
//                    var _doSomething: (@escaping () -> Void) -> Void
//            
//                    init(doSomething: @escaping (@escaping () -> Void) -> Void) {
//                        _doSomething = doSomething
//                    }
//            
//                    func doSomething(completionHandler: @escaping () -> Void) {
//                        _doSomething(completionHandler)
//                    }
//            
//                    private static var _production: MyClient?
//            
//                    static func production() -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient()
//            
//                        if _production == nil {
//                            _production = production
//                        }
//            
//                        return MyClient.ProtocolWitness(
//                            doSomething: production.doSomething
//                        )
//                    }
//                }
//            }
//            """
//        }
//    }
//    
//    func testMacro_expandsType_whenFunctionParametersContainsParamToVoidClosure_andClosureIsEscaping() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing
//            struct MyClient {
//                func doSomething(completionHandler: @escaping (Int) -> Void) { }
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//                func doSomething(completionHandler: @escaping (Int) -> Void) { }
//            
//                struct ProtocolWitness {
//                    var _doSomething: (@escaping (Int) -> Void) -> Void
//            
//                    init(doSomething: @escaping (@escaping (Int) -> Void) -> Void) {
//                        _doSomething = doSomething
//                    }
//            
//                    func doSomething(completionHandler: @escaping (Int) -> Void) {
//                        _doSomething(completionHandler)
//                    }
//            
//                    private static var _production: MyClient?
//            
//                    static func production() -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient()
//            
//                        if _production == nil {
//                            _production = production
//                        }
//            
//                        return MyClient.ProtocolWitness(
//                            doSomething: production.doSomething
//                        )
//                    }
//                }
//            }
//            """
//        }
//    }
//}
//
//// MARK: Formatting
//
//extension ProtocolWitnessingTests {
//    func testMacro_expandsType_whenContainingFunction_andFunctionHasExplicitVoidReturn() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing
//            struct MyClient {
//                func doSomething() -> Void { }
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//                func doSomething() -> Void { }
//            
//                struct ProtocolWitness {
//                    var _doSomething: () -> Void
//            
//                    init(doSomething: @escaping () -> Void) {
//                        _doSomething = doSomething
//                    }
//            
//                    func doSomething() -> Void {
//                        _doSomething()
//                    }
//            
//                    private static var _production: MyClient?
//            
//                    static func production() -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient()
//            
//                        if _production == nil {
//                            _production = production
//                        }
//            
//                        return MyClient.ProtocolWitness(
//                            doSomething: production.doSomething
//                        )
//                    }
//                }
//            }
//            """
//        }
//    }
//    
//    func testMacro_expandsType_whenContainingFunction_andFunctionHasExtraWhitespaceAroundReturnArrow() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing
//            struct MyClient {
//                func doSomething()   ->   Void { }
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//                func doSomething()   ->   Void { }
//            
//                struct ProtocolWitness {
//                    var _doSomething: () -> Void
//            
//                    init(doSomething: @escaping () -> Void) {
//                        _doSomething = doSomething
//                    }
//            
//                    func doSomething() -> Void {
//                        _doSomething()
//                    }
//            
//                    private static var _production: MyClient?
//            
//                    static func production() -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient()
//            
//                        if _production == nil {
//                            _production = production
//                        }
//            
//                        return MyClient.ProtocolWitness(
//                            doSomething: production.doSomething
//                        )
//                    }
//                }
//            }
//            """
//        }
//    }
//    
//    func testMacro_expandsType_whenContainingFunction_andFunctionHasExtraWhitespaceAroundFunctionName() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing
//            struct MyClient {
//                func    doSomething()    {    }
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//                func    doSomething()    {    }
//            
//                struct ProtocolWitness {
//                    var _doSomething: () -> Void
//            
//                    init(doSomething: @escaping () -> Void) {
//                        _doSomething = doSomething
//                    }
//            
//                    func doSomething() {
//                        _doSomething()
//                    }
//            
//                    private static var _production: MyClient?
//            
//                    static func production() -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient()
//            
//                        if _production == nil {
//                            _production = production
//                        }
//            
//                        return MyClient.ProtocolWitness(
//                            doSomething: production.doSomething
//                        )
//                    }
//                }
//            }
//            """
//        }
//    }
//    
//    func testMacro_expandsType_whenContainingFunction_andFunctionHasExtraNewlinesAroundFunctionBody() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing
//            struct MyClient {
//                func doSomething()
//                {
//                    /*some logic here*/
//                }
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//                func doSomething()
//                {
//                    /*some logic here*/
//                }
//            
//                struct ProtocolWitness {
//                    var _doSomething: () -> Void
//            
//                    init(doSomething: @escaping () -> Void) {
//                        _doSomething = doSomething
//                    }
//            
//                    func doSomething() {
//                        _doSomething()
//                    }
//            
//                    private static var _production: MyClient?
//            
//                    static func production() -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient()
//            
//                        if _production == nil {
//                            _production = production
//                        }
//            
//                        return MyClient.ProtocolWitness(
//                            doSomething: production.doSomething
//                        )
//                    }
//                }
//            }
//            """
//        }
//    }
//    
//    func testMacro_expandsType_whenContainingFunction_andFunctionHasExtraNewlinesAndWhitespaceEverywhere() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing
//            struct MyClient {
//                func    doSomething ()
//                
//                {
//                    
//                    /*some logic here*/
//                    
//                }
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//                func    doSomething ()
//                
//                {
//                    
//                    /*some logic here*/
//                    
//                }
//            
//                struct ProtocolWitness {
//                    var _doSomething: () -> Void
//            
//                    init(doSomething: @escaping () -> Void) {
//                        _doSomething = doSomething
//                    }
//            
//                    func doSomething() {
//                        _doSomething()
//                    }
//            
//                    private static var _production: MyClient?
//            
//                    static func production() -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient()
//            
//                        if _production == nil {
//                            _production = production
//                        }
//            
//                        return MyClient.ProtocolWitness(
//                            doSomething: production.doSomething
//                        )
//                    }
//                }
//            }
//            """
//        }
//    }
//}
//
//// MARK: - Properties
//
//// MARK: Only properties
//
//extension ProtocolWitnessingTests {
//    func testMacro_createsInitWithProperty_whenStructHasOneSimpleLetProperty_andNoFunctions() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing
//            struct MyClient {
//                let someLetProperty: Int
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//                let someLetProperty: Int
//            
//                struct ProtocolWitness {
//                    var someLetProperty: Int {
//                        get {
//                            _someLetProperty
//                        }
//                    }
//            
//                    var _someLetProperty: Int
//            
//                    init(someLetProperty: Int) {
//                        _someLetProperty = someLetProperty
//                    }
//            
//            
//            
//                    private static var _production: MyClient?
//            
//                    static func production(
//                        someLetProperty: Int
//                    ) -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient(
//                            someLetProperty: someLetProperty
//                        )
//            
//                        if _production == nil {
//                            _production = production
//                        }
//            
//                        return MyClient.ProtocolWitness(
//                            someLetProperty: production.someLetProperty
//                        )
//                    }
//                }
//            }
//            """
//        }
//    }
//    
//    func testMacro_createsInitWithProperty_whenStructHasOneSimpleVarProperty_andNoFunctions_andVarHasNoDefaultValue() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing
//            struct MyClient {
//                var someLetProperty: Int
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//                var someLetProperty: Int
//            
//                struct ProtocolWitness {
//                    var someLetProperty: Int {
//                        get {
//                            _someLetProperty
//                        }
//                    }
//            
//                    var _someLetProperty: Int
//            
//                    init(someLetProperty: Int) {
//                        _someLetProperty = someLetProperty
//                    }
//            
//            
//            
//                    private static var _production: MyClient?
//            
//                    static func production(
//                        someLetProperty: Int
//                    ) -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient(
//                            someLetProperty: someLetProperty
//                        )
//            
//                        if _production == nil {
//                            _production = production
//                        }
//            
//                        return MyClient.ProtocolWitness(
//                            someLetProperty: production.someLetProperty
//                        )
//                    }
//                }
//            }
//            """
//        }
//    }
//    
//    func testMacro_createsInitWithProperty_whenStructHasOneSimpleLetProperty_andNoFunctions_andLetHasDefaultValue_andExplicitType() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing
//            struct MyClient {
//                let someLetProperty: Int = 10
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//                let someLetProperty: Int = 10
//
//                struct ProtocolWitness {
//                    var someLetProperty: Int {
//                        get {
//                            _someLetProperty
//                        }
//                    }
//
//                    var _someLetProperty: Int = 10
//
//                    init() {
//                    }
//
//
//
//                    private static var _production: MyClient?
//
//                    static func production() -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient()
//
//                        if _production == nil {
//                            _production = production
//                        }
//
//                        return MyClient.ProtocolWitness()
//                    }
//                }
//            }
//            """
//        }
//    }
//    
//    func testMacro_createsInitWithProperty_whenStructHasOneSimpleLetProperty_andNoFunctions_andVarHasDefaultValue_andExplicitType() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing
//            struct MyClient {
//                var someLetProperty: Int = 10
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//                var someLetProperty: Int = 10
//
//                struct ProtocolWitness {
//                    var someLetProperty: Int = 10
//
//                    init() {
//                    }
//
//
//
//                    private static var _production: MyClient?
//
//                    static func production() -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient()
//
//                        if _production == nil {
//                            _production = production
//                        }
//
//                        return MyClient.ProtocolWitness()
//                    }
//                }
//            }
//            """
//        }
//    }
//    
//    func testMacro_createsInitWithProperty_whenStructHasOneSimpleLetProperty_andNoFunctions_andLetHasDefaultValue_butImplicitType() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing
//            struct MyClient {
//                let someLetProperty = 10
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//                let someLetProperty = 10
//
//                struct ProtocolWitness {
//                    init() {
//                    }
//
//                    private static var _production: MyClient?
//
//                    static func production() -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient()
//
//                        if _production == nil {
//                            _production = production
//                        }
//
//                        return MyClient.ProtocolWitness()
//                    }
//                }
//            }
//            """
//        }
//    }
//    
//    func testMacro_createsInitWithProperty_whenStructHasOneSimpleLetProperty_andNoFunctions_andVarHasDefaultValue_butImplicitType() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing
//            struct MyClient {
//                var someLetProperty = 10
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//                var someLetProperty = 10
//
//                struct ProtocolWitness {
//                    var someLetProperty = 10
//            
//                    init() {
//                    }
//
//            
//            
//                    private static var _production: MyClient?
//
//                    static func production() -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient()
//
//                        if _production == nil {
//                            _production = production
//                        }
//
//                        return MyClient.ProtocolWitness()
//                    }
//                }
//            }
//            """
//        }
//    }
//}
//
//// MARK: With functions
//
//extension ProtocolWitnessingTests {
//    func testMacro_createsInitWithProperty_whenStructHasOneSimpleLetProperty_andOneFunction() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing
//            struct MyClient {
//                let someLetProperty: Int
//            
//                func doSomething() { }
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//                let someLetProperty: Int
//            
//                func doSomething() { }
//            
//                struct ProtocolWitness {
//                    var someLetProperty: Int {
//                        get {
//                            _someLetProperty
//                        }
//                    }
//            
//                    var _someLetProperty: Int
//            
//                    var _doSomething: () -> Void
//
//                    init(
//                        someLetProperty: Int,
//                        doSomething: @escaping () -> Void
//                    ) {
//                        _someLetProperty = someLetProperty
//                        _doSomething = doSomething
//                    }
//            
//                    func doSomething() {
//                        _doSomething()
//                    }
//            
//                    private static var _production: MyClient?
//            
//                    static func production(
//                        someLetProperty: Int
//                    ) -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient(
//                            someLetProperty: someLetProperty
//                        )
//            
//                        if _production == nil {
//                            _production = production
//                        }
//            
//                        return MyClient.ProtocolWitness(
//                            someLetProperty: production.someLetProperty,
//                            doSomething: production.doSomething
//                        )
//                    }
//                }
//            }
//            """
//        }
//    }
//    
//    func testMacro_createsInitWithProperty_whenStructHasOneSimpleVarProperty_andOneFunction_andVarHasNoDefaultValue() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing
//            struct MyClient {
//                var someLetProperty: Int
//            
//                func doSomething() { }
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//                var someLetProperty: Int
//            
//                func doSomething() { }
//            
//                struct ProtocolWitness {
//                    var someLetProperty: Int {
//                        get {
//                            _someLetProperty
//                        }
//                    }
//            
//                    var _someLetProperty: Int
//            
//                    var _doSomething: () -> Void
//            
//                    init(
//                        someLetProperty: Int,
//                        doSomething: @escaping () -> Void
//                    ) {
//                        _someLetProperty = someLetProperty
//                        _doSomething = doSomething
//                    }
//            
//                    func doSomething() {
//                        _doSomething()
//                    }
//            
//                    private static var _production: MyClient?
//            
//                    static func production(
//                        someLetProperty: Int
//                    ) -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient(
//                            someLetProperty: someLetProperty
//                        )
//            
//                        if _production == nil {
//                            _production = production
//                        }
//            
//                        return MyClient.ProtocolWitness(
//                            someLetProperty: production.someLetProperty,
//                            doSomething: production.doSomething
//                        )
//                    }
//                }
//            }
//            """
//        }
//    }
//    
//    func testMacro_createsInitWithProperty_whenStructHasOneSimpleLetProperty_andOneFunction_andLetHasDefaultValue() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing
//            struct MyClient {
//                let someLetProperty = 532
//            
//                func doSomething() { }
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//                let someLetProperty = 532
//            
//                func doSomething() { }
//            
//                struct ProtocolWitness {
//                    var _doSomething: () -> Void
//            
//                    init(doSomething: @escaping () -> Void) {
//                        _doSomething = doSomething
//                    }
//            
//                    func doSomething() {
//                        _doSomething()
//                    }
//            
//                    private static var _production: MyClient?
//            
//                    static func production() -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient()
//            
//                        if _production == nil {
//                            _production = production
//                        }
//            
//                        return MyClient.ProtocolWitness(
//                            doSomething: production.doSomething
//                        )
//                    }
//                }
//            }
//            """
//        }
//    }
//    
//    func testMacro_createsInitWithProperty_whenStructHasOneSimpleLetProperty_andOneFunction_andVarHasDefaultValue() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing
//            struct MyClient {
//                var someLetProperty = 10
//            
//                func doSomething() { }
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//                var someLetProperty = 10
//            
//                func doSomething() { }
//            
//                struct ProtocolWitness {
//                    var someLetProperty = 10
//            
//                    var _doSomething: () -> Void
//            
//                    init(doSomething: @escaping () -> Void) {
//                        _doSomething = doSomething
//                    }
//            
//                    func doSomething() {
//                        _doSomething()
//                    }
//            
//                    private static var _production: MyClient?
//            
//                    static func production() -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient()
//            
//                        if _production == nil {
//                            _production = production
//                        }
//            
//                        return MyClient.ProtocolWitness(
//                            doSomething: production.doSomething
//                        )
//                    }
//                }
//            }
//            """
//        }
//    }
//}
//
//// MARK: Private
//
//extension ProtocolWitnessingTests {
//    func testMacro_doesNotIncludePrivateProperty_whenOnlyPrivateProperty() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing
//            struct MyClient {
//                private var somethingPrivate = true
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//                private var somethingPrivate = true
//            
//                struct ProtocolWitness {
//                    init() {
//                    }
//            
//                    private static var _production: MyClient?
//            
//                    static func production() -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient()
//            
//                        if _production == nil {
//                            _production = production
//                        }
//            
//                        return MyClient.ProtocolWitness()
//                    }
//                }
//            }
//            """
//        }
//    }
//    
//    func testMacro_doesNotIncludePrivateProperty_whenMixingPrivateProperty() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing
//            struct MyClient {
//                var somethingNotPrivate = true
//            
//                private var somethingPrivate = true
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//                var somethingNotPrivate = true
//            
//                private var somethingPrivate = true
//            
//                struct ProtocolWitness {
//                    var somethingNotPrivate = true
//            
//                    init() {
//                    }
//            
//            
//            
//                    private static var _production: MyClient?
//            
//                    static func production() -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient()
//            
//                        if _production == nil {
//                            _production = production
//                        }
//            
//                        return MyClient.ProtocolWitness()
//                    }
//                }
//            }
//            """
//        }
//    }
//}
//
//// MARK: Internal
//
//extension ProtocolWitnessingTests {
//    func testMacro_includesProperty_whenExplicitlySetAsInternal() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing
//            struct MyClient {
//                internal var somethingInternal = true
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//                internal var somethingInternal = true
//            
//                struct ProtocolWitness {
//                    internal var somethingInternal = true
//            
//                    init() {
//                    }
//            
//            
//            
//                    private static var _production: MyClient?
//            
//                    static func production() -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient()
//            
//                        if _production == nil {
//                            _production = production
//                        }
//            
//                        return MyClient.ProtocolWitness()
//                    }
//                }
//            }
//            """
//        }
//    }
//    
//    func testMacro_includesProperty_whenMix_andOneIsExplicitlySetAsInternal() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing
//            struct MyClient {
//                internal var somethingInternal = true
//            
//                var somethingInternal = true
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//                internal var somethingInternal = true
//            
//                var somethingInternal = true
//            
//                struct ProtocolWitness {
//                    internal var somethingInternal = true
//            
//                    var somethingInternal = true
//            
//                    init() {
//                    }
//            
//            
//            
//                    private static var _production: MyClient?
//            
//                    static func production() -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient()
//            
//                        if _production == nil {
//                            _production = production
//                        }
//            
//                        return MyClient.ProtocolWitness()
//                    }
//                }
//            }
//            """
//        }
//    }
//}
//
//// MARK: Public
//
//extension ProtocolWitnessingTests {
//    func testMacro_includesProperty_whenSetAsPublic() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing
//            struct MyClient {
//                public var somethingPublic = true
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//                public var somethingPublic = true
//            
//                struct ProtocolWitness {
//                    public var somethingPublic = true
//            
//                    init() {
//                    }
//            
//            
//            
//                    private static var _production: MyClient?
//            
//                    static func production() -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient()
//            
//                        if _production == nil {
//                            _production = production
//                        }
//            
//                        return MyClient.ProtocolWitness()
//                    }
//                }
//            }
//            """
//        }
//    }
//    
//    func testMacro_includesProperty_whenMix_andOneIsSetAsPublic() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing
//            struct MyClient {
//                public var somethingPublic = true
//            
//                var somethingInternal = true
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//                public var somethingPublic = true
//            
//                var somethingInternal = true
//            
//                struct ProtocolWitness {
//                    public var somethingPublic = true
//            
//                    var somethingInternal = true
//            
//                    init() {
//                    }
//            
//            
//            
//                    private static var _production: MyClient?
//            
//                    static func production() -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient()
//            
//                        if _production == nil {
//                            _production = production
//                        }
//            
//                        return MyClient.ProtocolWitness()
//                    }
//                }
//            }
//            """
//        }
//    }
//}
//
//// MARK: Open
//
//extension ProtocolWitnessingTests {
//    func testMacro_includesProperty_whenSetAsOpen() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing
//            struct MyClient {
//                open var somethingOpen = true
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//                open var somethingOpen = true
//            
//                struct ProtocolWitness {
//                    open var somethingOpen = true
//            
//                    init() {
//                    }
//            
//            
//            
//                    private static var _production: MyClient?
//            
//                    static func production() -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient()
//            
//                        if _production == nil {
//                            _production = production
//                        }
//            
//                        return MyClient.ProtocolWitness()
//                    }
//                }
//            }
//            """
//        }
//    }
//    
//    func testMacro_includesProperty_whenMix_andOneIsSetAsOpen() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing
//            struct MyClient {
//                open var somethingOpen = true
//            
//                var somethingElse = true
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//                open var somethingOpen = true
//            
//                var somethingElse = true
//            
//                struct ProtocolWitness {
//                    open var somethingOpen = true
//            
//                    var somethingElse = true
//            
//                    init() {
//                    }
//            
//            
//            
//                    private static var _production: MyClient?
//            
//                    static func production() -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient()
//            
//                        if _production == nil {
//                            _production = production
//                        }
//            
//                        return MyClient.ProtocolWitness()
//                    }
//                }
//            }
//            """
//        }
//    }
//}
//
//// MARK: Getter
//
//extension ProtocolWitnessingTests {
//    func testMacro_addsGetterToWitness_whenPropertyHasGetOnlyProperty_andGetterSpansOneLineOnly() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing
//            struct MyClient {
//                var isThing: Bool { true }
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//                var isThing: Bool { true }
//            
//                struct ProtocolWitness {
//                    var isThing: Bool {
//                        get {
//                            _isThing
//                        }
//                    }
//
//                    var _isThing: Bool = {
//                        true
//                    }()
//
//                    init() {
//                    }
//            
//            
//            
//                    private static var _production: MyClient?
//            
//                    static func production() -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient()
//            
//                        if _production == nil {
//                            _production = production
//                        }
//            
//                        return MyClient.ProtocolWitness()
//                    }
//                }
//            }
//            """
//        }
//    }
//    
//    func testMacro_addsGetterToWitness_whenPropertyHasGetOnlyProperty_andGetterSpansMultipleLines() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing
//            struct MyClient {
//                var isThing: Bool {
//                    true
//                }
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//                var isThing: Bool {
//                    true
//                }
//            
//                struct ProtocolWitness {
//                    var isThing: Bool {
//                        get {
//                            _isThing
//                        }
//                    }
//            
//                    var _isThing: Bool = {
//                        true
//                    }()
//
//                    init() {
//                    }
//            
//            
//            
//                    private static var _production: MyClient?
//            
//                    static func production() -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient()
//            
//                        if _production == nil {
//                            _production = production
//                        }
//            
//                        return MyClient.ProtocolWitness()
//                    }
//                }
//            }
//            """
//        }
//    }
//    
//    func testMacro_addsGetterToWitness_whenPropertyHasGetOnlyProperty_andGetterContainsComplexCode() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing
//            struct MyClient {
//                var isThing: Bool {
//                    let myThing = true
//            
//                    print(myThing)
//            
//                    return myThing
//                }
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//                var isThing: Bool {
//                    let myThing = true
//            
//                    print(myThing)
//            
//                    return myThing
//                }
//            
//                struct ProtocolWitness {
//                    var isThing: Bool {
//                        get {
//                            _isThing
//                        }
//                    }
//            
//                    var _isThing: Bool = {
//                        let myThing = true
//            
//                                print(myThing)
//            
//                                return myThing
//                    }()
//
//                    init() {
//                    }
//            
//            
//            
//                    private static var _production: MyClient?
//            
//                    static func production() -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient()
//            
//                        if _production == nil {
//                            _production = production
//                        }
//            
//                        return MyClient.ProtocolWitness()
//                    }
//                }
//            }
//            """
//        }
//    }
//    
//    func testMacro_addsGetterToWitness_whenPropertyHasGetOnlyProperty_andGetterHasExplicitGetWrapper() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing
//            struct MyClient {
//                var isThing: Bool {
//                    get { true }
//                }
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//                var isThing: Bool {
//                    get { true }
//                }
//            
//                struct ProtocolWitness {
//                    var isThing: Bool {
//                        get {
//                            _isThing
//                        }
//                    }
//            
//                    var _isThing: Bool = {
//                        true
//                    }()
//            
//                    init() {
//                    }
//            
//            
//            
//                    private static var _production: MyClient?
//            
//                    static func production() -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient()
//            
//                        if _production == nil {
//                            _production = production
//                        }
//            
//                        return MyClient.ProtocolWitness()
//                    }
//                }
//            }
//            """
//        }
//    }
//}
//
//// MARK: Async getter
//
//extension ProtocolWitnessingTests {
//    func testMacro_addsAsyncGetterToWitness_whenPropertyHasAsyncGetOnlyProperty_andSpansOneLineOnly() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing
//            struct MyClient {
//                var isAsync: Bool {
//                    get async { true }
//                }
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//                var isAsync: Bool {
//                    get async { true }
//                }
//            
//                struct ProtocolWitness {
//                    var isAsync: Bool {
//                        get async {
//                            _isAsync
//                        }
//                    }
//            
//                    var _isAsync: Bool = {
//                        true
//                    }()
//            
//                    init() {
//                    }
//            
//            
//            
//                    private static var _production: MyClient?
//            
//                    static func production() -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient()
//            
//                        if _production == nil {
//                            _production = production
//                        }
//            
//                        return MyClient.ProtocolWitness()
//                    }
//                }
//            }
//            """
//        }
//    }
//    
//    func testMacro_addsAsyncGetterToWitness_whenPropertyHasAsyncGetOnlyProperty_andSpansMultipleLines() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing
//            struct MyClient {
//                var isAsync: Bool {
//                    get async {
//                        true
//                    }
//                }
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//                var isAsync: Bool {
//                    get async {
//                        true
//                    }
//                }
//            
//                struct ProtocolWitness {
//                    var isAsync: Bool {
//                        get async {
//                            _isAsync
//                        }
//                    }
//            
//                    var _isAsync: Bool = {
//                        true
//                    }()
//            
//                    init() {
//                    }
//            
//            
//            
//                    private static var _production: MyClient?
//            
//                    static func production() -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient()
//            
//                        if _production == nil {
//                            _production = production
//                        }
//            
//                        return MyClient.ProtocolWitness()
//                    }
//                }
//            }
//            """
//        }
//    }
//    
//    func testMacro_addsAsyncGetterToWitness_whenPropertyHasAsyncGetOnlyProperty_andGetterContainsComplexCode() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing
//            struct MyClient {
//                var isThing: Bool {
//                    get async {
//                        let myThing = true
//                
//                        print(myThing)
//                
//                        return myThing
//                    }
//                }
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//                var isThing: Bool {
//                    get async {
//                        let myThing = true
//                
//                        print(myThing)
//                
//                        return myThing
//                    }
//                }
//            
//                struct ProtocolWitness {
//                    var isThing: Bool {
//                        get async {
//                            _isThing
//                        }
//                    }
//            
//                    var _isThing: Bool = {
//                        let myThing = true
//            
//                                    print(myThing)
//            
//                                    return myThing
//                    }()
//            
//                    init() {
//                    }
//            
//            
//            
//                    private static var _production: MyClient?
//            
//                    static func production() -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient()
//            
//                        if _production == nil {
//                            _production = production
//                        }
//            
//                        return MyClient.ProtocolWitness()
//                    }
//                }
//            }
//            """
//        }
//    }
//}
//
//// MARK: Throwing getter
//
//extension ProtocolWitnessingTests {
//    func testMacro_addsThrowsGetterToWitness_whenPropertyHasThrowsGetOnlyProperty_andSpansOneLineOnly() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing
//            struct MyClient {
//                var isAsync: Bool {
//                    get throws { true }
//                }
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//                var isAsync: Bool {
//                    get throws { true }
//                }
//            
//                struct ProtocolWitness {
//                    var isAsync: Bool {
//                        get throws {
//                            try _isAsync()
//                        }
//                    }
//            
//                    var _isAsync: () throws -> Bool = {
//                        true
//                    }
//            
//                    init() {
//                    }
//            
//            
//            
//                    private static var _production: MyClient?
//            
//                    static func production() -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient()
//            
//                        if _production == nil {
//                            _production = production
//                        }
//            
//                        return MyClient.ProtocolWitness()
//                    }
//                }
//            }
//            """
//        }
//    }
//    
//    func testMacro_addsThrowsGetterToWitness_whenPropertyHasThrowsGetOnlyProperty_andSpansMultipleLines() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing
//            struct MyClient {
//                var isAsync: Bool {
//                    get throws {
//                        true
//                    }
//                }
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//                var isAsync: Bool {
//                    get throws {
//                        true
//                    }
//                }
//            
//                struct ProtocolWitness {
//                    var isAsync: Bool {
//                        get throws {
//                            try _isAsync()
//                        }
//                    }
//            
//                    var _isAsync: () throws -> Bool = {
//                        true
//                    }
//            
//                    init() {
//                    }
//            
//            
//            
//                    private static var _production: MyClient?
//            
//                    static func production() -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient()
//            
//                        if _production == nil {
//                            _production = production
//                        }
//            
//                        return MyClient.ProtocolWitness()
//                    }
//                }
//            }
//            """
//        }
//    }
//}
//
//// MARK: Static var
//
//extension ProtocolWitnessingTests {
//    func testMacro_expandsMacro_whenStaticVarGetOnlyProperty() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing
//            struct MyClient {
//                static var returnSomething: [String] { [] }
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//                static var returnSomething: [String] { [] }
//
//                struct ProtocolWitness {
//                    static var returnSomething: [String] {
//                        get {
//                            _returnSomething
//                        }
//                    }
//            
//                    static var _returnSomething: [String] = {
//                        []
//                    }()
//
//                    init() {
//                    }
//
//
//
//                    private static var _production: MyClient?
//
//                    static func production() -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient()
//
//                        if _production == nil {
//                            _production = production
//                        }
//
//                        return MyClient.ProtocolWitness()
//                    }
//                }
//            }
//            """
//        }
//    }
//    
//    func testMacro_expandsMacro_whenStaticVarGetOnlyProperty_andExplicitGetter() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing
//            struct MyClient {
//                static var returnSomething: [String] {
//                    get { [] }
//                }
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//                static var returnSomething: [String] {
//                    get { [] }
//                }
//            
//                struct ProtocolWitness {
//                    static var returnSomething: [String] {
//                        get {
//                            _returnSomething
//                        }
//                    }
//            
//                    static var _returnSomething: [String] = {
//                        []
//                    }()
//            
//                    init() {
//                    }
//            
//            
//            
//                    private static var _production: MyClient?
//            
//                    static func production() -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient()
//            
//                        if _production == nil {
//                            _production = production
//                        }
//            
//                        return MyClient.ProtocolWitness()
//                    }
//                }
//            }
//            """
//        }
//    }
//    
//    func testMacro_expandsMacro_whenStaticVarGetOnlyProperty_andExplicitGetter_andSetter() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing
//            struct MyClient {
//                static var returnSomething: [String] {
//                    get { [] }
//                    set { print(newValue) }
//                }
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//                static var returnSomething: [String] {
//                    get { [] }
//                    set { print(newValue) }
//                }
//            
//                struct ProtocolWitness {
//                    static var returnSomething: [String] {
//                        get {
//                            _returnSomething
//                        }
//                        set {
//                            print(newValue)
//                        }
//                    }
//            
//                    static var _returnSomething: [String] = {
//                        []
//                    }()
//            
//                    init() {
//                    }
//            
//            
//            
//                    private static var _production: MyClient?
//            
//                    static func production() -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient()
//            
//                        if _production == nil {
//                            _production = production
//                        }
//            
//                        return MyClient.ProtocolWitness()
//                    }
//                }
//            }
//            """
//        }
//    }
//}
//
//// MARK: Lazy var
//
//extension ProtocolWitnessingTests {
//    func testMacro_expandsMacro_whenLazyVar() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing
//            struct MyClient {
//                lazy var getSomething: Bool = {
//                    true
//                }()
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//                lazy var getSomething: Bool = {
//                    true
//                }()
//
//                struct ProtocolWitness {
//                    lazy var getSomething: Bool = {
//                        true
//                    }()
//
//                    init() {
//                    }
//
//
//
//                    private static var _production: MyClient?
//
//                    static func production() -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient()
//
//                        if _production == nil {
//                            _production = production
//                        }
//
//                        return MyClient.ProtocolWitness()
//                    }
//                }
//            }
//            """
//        }
//    }
//    
//    func testMacro_expandsMacro_whenLazyVar_andComplexContents() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing
//            struct MyClient {
//                lazy var getSomething: Bool = {
//                    let thing = true
//                    
//                    print("thing", thing)
//            
//                    return thing
//                }()
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//                lazy var getSomething: Bool = {
//                    let thing = true
//                    
//                    print("thing", thing)
//
//                    return thing
//                }()
//
//                struct ProtocolWitness {
//                    lazy var getSomething: Bool = {
//                        let thing = true
//
//                        print("thing", thing)
//
//                        return thing
//                    }()
//
//                    init() {
//                    }
//
//
//
//                    private static var _production: MyClient?
//
//                    static func production() -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient()
//
//                        if _production == nil {
//                            _production = production
//                        }
//
//                        return MyClient.ProtocolWitness()
//                    }
//                }
//            }
//            """
//        }
//    }
//}
//
//// MARK: Setter
//
//extension ProtocolWitnessingTests {
//    func testMacro_addsSetterToWitness_whenPropertyHasGetterAndSetter_andSetterSpansOneLineOnly() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing
//            struct MyClient {
//                var isThing: Bool {
//                    get { true }
//                    set { print(newValue) }
//                }
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//                var isThing: Bool {
//                    get { true }
//                    set { print(newValue) }
//                }
//            
//                struct ProtocolWitness {
//                    var isThing: Bool {
//                        get {
//                            _isThing
//                        }
//                        set {
//                            print(newValue)
//                        }
//                    }
//            
//                    var _isThing: Bool = {
//                        true
//                    }()
//            
//                    init() {
//                    }
//            
//            
//            
//                    private static var _production: MyClient?
//            
//                    static func production() -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient()
//            
//                        if _production == nil {
//                            _production = production
//                        }
//            
//                        return MyClient.ProtocolWitness()
//                    }
//                }
//            }
//            """
//        }
//    }
//    
//    func testMacro_addsSetterToWitness_whenPropertyHasGetterAndSetter_andSetterSpansMultipleLines() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing
//            struct MyClient {
//                var isThing: Bool {
//                    get { true }
//                    set {
//                        print(newValue)
//                    }
//                }
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//                var isThing: Bool {
//                    get { true }
//                    set {
//                        print(newValue)
//                    }
//                }
//            
//                struct ProtocolWitness {
//                    var isThing: Bool {
//                        get {
//                            _isThing
//                        }
//                        set {
//                                    print(newValue)
//                                }
//                    }
//            
//                    var _isThing: Bool = {
//                        true
//                    }()
//            
//                    init() {
//                    }
//            
//            
//            
//                    private static var _production: MyClient?
//            
//                    static func production() -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient()
//            
//                        if _production == nil {
//                            _production = production
//                        }
//            
//                        return MyClient.ProtocolWitness()
//                    }
//                }
//            }
//            """
//        }
//    }
//    
//    func testMacro_addsSetterToWitness_whenPropertyHasGetterAndSetter_andSetterIsComplex() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing
//            struct MyClient {
//                var isThing: Bool {
//                    get { true }
//                    set {
//                        let thing = 443
//                        let thing2 = thing * (newValue ? 1 : 0)
//            
//                        print(thing2)
//                    }
//                }
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//                var isThing: Bool {
//                    get { true }
//                    set {
//                        let thing = 443
//                        let thing2 = thing * (newValue ? 1 : 0)
//            
//                        print(thing2)
//                    }
//                }
//            
//                struct ProtocolWitness {
//                    var isThing: Bool {
//                        get {
//                            _isThing
//                        }
//                        set {
//                                    let thing = 443
//                                    let thing2 = thing * (newValue ? 1 : 0)
//            
//                                    print(thing2)
//                                }
//                    }
//            
//                    var _isThing: Bool = {
//                        true
//                    }()
//            
//                    init() {
//                    }
//            
//            
//            
//                    private static var _production: MyClient?
//            
//                    static func production() -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient()
//            
//                        if _production == nil {
//                            _production = production
//                        }
//            
//                        return MyClient.ProtocolWitness()
//                    }
//                }
//            }
//            """
//        }
//    }
//}
//
//// MARK: Mix of computed
//
//extension ProtocolWitnessingTests {
//    func testMacro_addsGettersToWitness_whenPropertyHasAsyncGetter_andPropertyAlsoHasNonAsyncGetter() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing
//            struct MyClient {
//                var isThing: Bool {
//                    get { true }
//                }
//                
//                var isAsync: Bool {
//                    get async { true }
//                }
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//                var isThing: Bool {
//                    get { true }
//                }
//                
//                var isAsync: Bool {
//                    get async { true }
//                }
//            
//                struct ProtocolWitness {
//                    var isThing: Bool {
//                        get {
//                            _isThing
//                        }
//                    }
//            
//                    var _isThing: Bool = {
//                        true
//                    }()
//            
//                    var isAsync: Bool {
//                        get async {
//                            _isAsync
//                        }
//                    }
//            
//                    var _isAsync: Bool = {
//                        true
//                    }()
//            
//                    init() {
//                    }
//            
//            
//            
//                    private static var _production: MyClient?
//            
//                    static func production() -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient()
//            
//                        if _production == nil {
//                            _production = production
//                        }
//            
//                        return MyClient.ProtocolWitness()
//                    }
//                }
//            }
//            """
//        }
//    }
//}
//
//// MARK: - Actors
//
//// MARK: MainActor
//
//extension ProtocolWitnessingTests {
//    func testMacro_setsWitnessAsMainActor_whenStructIsMainActor() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing
//            @MainActor
//            struct MyClient { }
//            """
//        } expansion: {
//            """
//            @MainActor
//            struct MyClient { 
//
//                struct ProtocolWitness {
//                    init() {
//                    }
//
//                    private static var _production: MyClient?
//
//                    @MainActor
//                    static func production() -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient()
//
//                        if _production == nil {
//                            _production = production
//                        }
//
//                        return MyClient.ProtocolWitness()
//                    }
//                }}
//            """
//        }
//    }
//}
//
//// MARK: - Mixed
//
//// MARK: Properties and functions
//
//extension ProtocolWitnessingTests {
//    func testMacro_addsMixedInit_andMixedProperty_whenMixingFunctionsReturnTypes() throws {
//        assertMacro {
//            """
//            class Thing {}
//            @ProtocolWitnessing
//            struct MyClient {
//                func returnsVoid() { }
//                func returnsAThing() -> Thing { .init() }
//            }
//            """
//        } expansion: {
//            """
//            class Thing {}
//            struct MyClient {
//                func returnsVoid() { }
//                func returnsAThing() -> Thing { .init() }
//            
//                struct ProtocolWitness {
//                    var _returnsVoid: () -> Void
//            
//                    var _returnsAThing: () -> Thing
//            
//                    init(
//                        returnsVoid: @escaping () -> Void,
//                        returnsAThing: @escaping () -> Thing
//                    ) {
//                        _returnsVoid = returnsVoid
//                        _returnsAThing = returnsAThing
//                    }
//            
//                    func returnsVoid() {
//                        _returnsVoid()
//                    }
//            
//                    func returnsAThing() -> Thing {
//                        _returnsAThing()
//                    }
//            
//                    private static var _production: MyClient?
//            
//                    static func production() -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient()
//            
//                        if _production == nil {
//                            _production = production
//                        }
//            
//                        return MyClient.ProtocolWitness(
//                            returnsVoid: production.returnsVoid,
//                            returnsAThing: production.returnsAThing
//                        )
//                    }
//                }
//            }
//            """
//        }
//    }
//}
//
//// MARK: Multiple macros
//
//extension ProtocolWitnessingTests {
//    func testMacro_expandsWithAttribute_whenAddingExtraAttributes() throws {
//        assertMacro {
//            """
//            class Thing {}
//            
//            @SomeAttribute
//            @ProtocolWitnessing
//            struct MyClient {
//                func returnsVoid() { }
//                func returnsAThing() -> Thing { .init() }
//            }
//            """
//        } expansion: {
//            """
//            class Thing {}
//            
//            @SomeAttribute
//            struct MyClient {
//                func returnsVoid() { }
//                func returnsAThing() -> Thing { .init() }
//            
//                struct ProtocolWitness {
//                    var _returnsVoid: () -> Void
//            
//                    var _returnsAThing: () -> Thing
//            
//                    init(
//                        returnsVoid: @escaping () -> Void,
//                        returnsAThing: @escaping () -> Thing
//                    ) {
//                        _returnsVoid = returnsVoid
//                        _returnsAThing = returnsAThing
//                    }
//            
//                    func returnsVoid() {
//                        _returnsVoid()
//                    }
//            
//                    func returnsAThing() -> Thing {
//                        _returnsAThing()
//                    }
//            
//                    private static var _production: MyClient?
//            
//                    static func production() -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient()
//            
//                        if _production == nil {
//                            _production = production
//                        }
//            
//                        return MyClient.ProtocolWitness(
//                            returnsVoid: production.returnsVoid,
//                            returnsAThing: production.returnsAThing
//                        )
//                    }
//                }
//            }
//            """
//        }
//    }
//}
//
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
//
//// MARK: - Parameters
//
//// MARK: None
//
//extension ProtocolWitnessingTests {
//    func testMacro_correctDefaults_whenNoParametersAreSet() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing
//            struct MyClient {
//                func returnsVoid() { }
//                func returnsAThing() -> Thing { }
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//                func returnsVoid() { }
//                func returnsAThing() -> Thing { }
//            
//                struct ProtocolWitness {
//                    var _returnsVoid: () -> Void
//            
//                    var _returnsAThing: () -> Thing
//            
//                    init(
//                        returnsVoid: @escaping () -> Void,
//                        returnsAThing: @escaping () -> Thing
//                    ) {
//                        _returnsVoid = returnsVoid
//                        _returnsAThing = returnsAThing
//                    }
//            
//                    func returnsVoid() {
//                        _returnsVoid()
//                    }
//            
//                    func returnsAThing() -> Thing {
//                        _returnsAThing()
//                    }
//            
//                    private static var _production: MyClient?
//            
//                    static func production() -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient()
//            
//                        if _production == nil {
//                            _production = production
//                        }
//            
//                        return MyClient.ProtocolWitness(
//                            returnsVoid: production.returnsVoid,
//                            returnsAThing: production.returnsAThing
//                        )
//                    }
//                }
//            }
//            """
//        }
//    }
//}
//
//// MARK: typeName
//
//extension ProtocolWitnessingTests {
//    func testMacro_usesCustomTypeName_whenTypeNameParameterIsSet_andTypeHasNoFunctions() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing(typeName: "MyCustomWitnessTypeName")
//            struct MyClient {
//            
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//            
//                struct MyCustomWitnessTypeName {
//                    init() {
//                    }
//            
//                    private static var _production: MyClient?
//            
//                    static func production() -> MyClient.MyCustomWitnessTypeName {
//                        let production = _production ?? MyClient()
//            
//                        if _production == nil {
//                            _production = production
//                        }
//            
//                        return MyClient.MyCustomWitnessTypeName()
//                    }
//                }
//            
//            }
//            """
//        }
//    }
//    
//    func testMacro_usesCustomTypeName_whenTypeNameParameterIsSet_andTypeHasOneFunction() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing(typeName: "MyCustomWitnessTypeName")
//            struct MyClient {
//                func myFunction() {}
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//                func myFunction() {}
//            
//                struct MyCustomWitnessTypeName {
//                    var _myFunction: () -> Void
//            
//                    init(myFunction: @escaping () -> Void) {
//                        _myFunction = myFunction
//                    }
//            
//                    func myFunction() {
//                        _myFunction()
//                    }
//            
//                    private static var _production: MyClient?
//            
//                    static func production() -> MyClient.MyCustomWitnessTypeName {
//                        let production = _production ?? MyClient()
//            
//                        if _production == nil {
//                            _production = production
//                        }
//            
//                        return MyClient.MyCustomWitnessTypeName(
//                            myFunction: production.myFunction
//                        )
//                    }
//                }
//            }
//            """
//        }
//    }
//}
//
//// MARK: productionInstanceName
//
//extension ProtocolWitnessingTests {
//    func testMacro_usesProductionNameAsTheInstanceName_whenProductionInstanceNameParameterIsSet() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing(productionInstanceName: "live")
//            struct MyClient {
//                func returnsVoid() { }
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//                func returnsVoid() { }
//            
//                struct ProtocolWitness {
//                    var _returnsVoid: () -> Void
//            
//                    init(returnsVoid: @escaping () -> Void) {
//                        _returnsVoid = returnsVoid
//                    }
//            
//                    func returnsVoid() {
//                        _returnsVoid()
//                    }
//            
//                    private static var _live: MyClient?
//            
//                    static func live() -> MyClient.ProtocolWitness {
//                        let live = _live ?? MyClient()
//            
//                        if _live == nil {
//                            _live = live
//                        }
//            
//                        return MyClient.ProtocolWitness(
//                            returnsVoid: live.returnsVoid
//                        )
//                    }
//                }
//            }
//            """
//        }
//    }
//}
//
//// MARK: typeName and productionInstanceName
//
//extension ProtocolWitnessingTests {
//    func testMacro_usesCustomTypeName_andProductionInstanceName_whenBothParametersAreSet() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing(typeName: "MyCustomTypeWitness", productionInstanceName: "live")
//            struct MyClient {
//                func returnsVoid() { }
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//                func returnsVoid() { }
//            
//                struct MyCustomTypeWitness {
//                    var _returnsVoid: () -> Void
//            
//                    init(returnsVoid: @escaping () -> Void) {
//                        _returnsVoid = returnsVoid
//                    }
//            
//                    func returnsVoid() {
//                        _returnsVoid()
//                    }
//            
//                    private static var _live: MyClient?
//            
//                    static func live() -> MyClient.MyCustomTypeWitness {
//                        let live = _live ?? MyClient()
//            
//                        if _live == nil {
//                            _live = live
//                        }
//            
//                        return MyClient.MyCustomTypeWitness(
//                            returnsVoid: live.returnsVoid
//                        )
//                    }
//                }
//            }
//            """
//        }
//    }
//}
//
//// MARK: productionInstanceName
//
////extension ProtocolWitnessingTests {
////    func testMacro_createsExtraWitnesses_whenExtraWitnessNamesIsNotEmpty() throws {
////        assertMacro {
////            """
////            @ProtocolWitnessing(typeName: "TypeName", productionInstanceName: "InstanceName", extraWitnessNames: ["test", "preview"])
////            struct MyClient {
////                func doSomething() { }
////            }
////            """
////        }
////    }
////}
//
//// MARK: - Misc.
//
//extension ProtocolWitnessingTests {
//    func testMacro_addsNestedTypes() throws {
//        assertMacro {
//            """
//            @ProtocolWitnessing
//            struct MyClient {
//                var id: Int = 1
//            
//                enum MyError: Error {
//                    case errorOne
//                    case errorTwo
//                }
//            
//                func doSomething() throws {
//                    print("Prod id", id)
//            
//                    throw MyError.errorTwo
//                }
//            }
//            """
//        } expansion: {
//            """
//            struct MyClient {
//                var id: Int = 1
//            
//                enum MyError: Error {
//                    case errorOne
//                    case errorTwo
//                }
//            
//                func doSomething() throws {
//                    print("Prod id", id)
//            
//                    throw MyError.errorTwo
//                }
//            
//                struct ProtocolWitness {
//                    var id: Int = 1
//
//                    var _doSomething: () throws -> Void
//
//                    init(doSomething: @escaping () throws -> Void) {
//                        _doSomething = doSomething
//                    }
//            
//                    func doSomething() throws {
//                        try _doSomething()
//                    }
//            
//                    private static var _production: MyClient?
//            
//                    static func production() -> MyClient.ProtocolWitness {
//                        let production = _production ?? MyClient()
//            
//                        if _production == nil {
//                            _production = production
//                        }
//            
//                        return MyClient.ProtocolWitness(
//                            doSomething: production.doSomething
//                        )
//                    }
//                }
//            }
//            """
//        }
//    }
//}
//
//// MARK: - Assistance
//
////extension ProtocolWitnessingTests {
////    func testMacroActualOutputByForcingRecordToTrue() throws {
////        assertMacro(record: true) {
////            """
////            @ProtocolWitnessing
////            struct MyClient {
////                var one: Int = 1
////            
////                static var strings: [String] = [
////                    "a", "b", "c"
////                ]
////            }
////            """
////        } expansion: {
////            """
////            struct MyClient {
////                var one: Int = 1
////            
////                static var strings: [String] = [
////                    "a", "b", "c"
////                ]
////            
////                struct ProtocolWitness {
////                    var one: Int = {
////                        1
////                    }()
////            
////                    static var strings: [String] = {
////                        [
////                                "a", "b", "c"
////                            ]
////                    }()
////            
////                    init() {
////            
////                    }
////            
////            
////            
////                    private static var _production: MyClient?
////            
////                    static func production() -> MyClient.ProtocolWitness {
////                        let production = _production ?? MyClient()
////            
////                        if _production == nil {
////                            _production = production
////                        }
////            
////                        return MyClient.ProtocolWitness()
////                    }
////                }
////            }
////            """
////        }
////    }
//}
#else
final class ProtocolWitnessingTests: XCTestCase {
    func testMacro() throws {
        throw XCTSkip("macros are only supported when running tests for the host platform")
    }
}
#endif
