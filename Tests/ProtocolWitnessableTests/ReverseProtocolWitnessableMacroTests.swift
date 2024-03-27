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
#else
final class ProtocolWitnessableTests: XCTestCase {
    func testMacro() throws {
        throw XCTSkip("macros are only supported when running tests for the host platform")
    }
}
#endif
