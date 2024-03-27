import MacroTesting
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(ProtocolWitnessableMacros)
import ProtocolWitnessableMacros

final class ReverseProtocolWitnessableTests: XCTestCase {
    override func invokeTest() {
//        withMacroTesting(isRecording: true, macros: [
        withMacroTesting(macros: [
            "ReverseProtocolWitnessable": ReverseProtocolWitnessableMacro.self,
        ]) {
            super.invokeTest()
        }
    }
}

// MARK: - Attachment checking

extension ReverseProtocolWitnessableTests {
    func test_throwsError_whenAttachedToProtocol() throws {
        assertMacro {
            """
            @ReverseProtocolWitnessable
            protocol MyClient { }
            """
        } diagnostics: {
            """
            @ReverseProtocolWitnessable
            ┬──────────────────────────
            ╰─ 🛑 @ReverseProtocolWitnessable cannot be attached to protocols
            protocol MyClient { }
            """
        }
    }
}

// MARK: - Struct

// MARK: Properties

extension ReverseProtocolWitnessableTests {
    func test_extractsPropertyToGetOnlyVar_whenStruct_andLet_andExplicitType() throws {
        assertMacro {
            """
            @ReverseProtocolWitnessable
            struct MyClient {
                let thing: String = ""
            }
            """
        } expansion: {
            """
            struct MyClient {
                let thing: String = ""
            }
            
            @ProtocolWitnessable
            protocol MyClientReverseProtocolWitness {
                var thing: String {
                    get
                }
            }
            """
        }
    }
    
    func test_extractsPropertyToGetOnlyVar_whenStruct_andLet_andImplicitStringType() throws {
        assertMacro {
            """
            @ReverseProtocolWitnessable
            struct MyClient {
                let thing = ""
            }
            """
        } expansion: {
            """
            struct MyClient {
                let thing = ""
            }
            
            @ProtocolWitnessable
            protocol MyClientReverseProtocolWitness {
                var thing: String {
                    get
                }
            }
            """
        }
    }
    
    func test_extractsPropertyToGetOnlyVar_whenStruct_andLet_andImplicitIntType() throws {
        assertMacro {
            """
            @ReverseProtocolWitnessable
            struct MyClient {
                let thing = 1
            }
            """
        } expansion: {
            """
            struct MyClient {
                let thing = 1
            }
            
            @ProtocolWitnessable
            protocol MyClientReverseProtocolWitness {
                var thing: Int {
                    get
                }
            }
            """
        }
    }
    
    func test_extractsPropertyToGetOnlyVar_whenStruct_andLet_andImplicitBoolType() throws {
        assertMacro {
            """
            @ReverseProtocolWitnessable
            struct MyClient {
                let thing = false
            }
            """
        } expansion: {
            """
            struct MyClient {
                let thing = false
            }
            
            @ProtocolWitnessable
            protocol MyClientReverseProtocolWitness {
                var thing: Bool {
                    get
                }
            }
            """
        }
    }
    
    func test_extractsPropertyToGetOnlyVar_whenStruct_andLet_andImplicitDoubleType() throws {
        assertMacro {
            """
            @ReverseProtocolWitnessable
            struct MyClient {
                let thing = 0.5
            }
            """
        } expansion: {
            """
            struct MyClient {
                let thing = 0.5
            }
            
            @ProtocolWitnessable
            protocol MyClientReverseProtocolWitness {
                var thing: Double {
                    get
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
