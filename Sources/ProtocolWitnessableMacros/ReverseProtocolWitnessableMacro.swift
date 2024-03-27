import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics


public struct ReverseProtocolWitnessableMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard declaration.is(ProtocolDeclSyntax.self) == false else {
            throw ReverseProtocolWitnessableError.noProtocolAllowed
        }
        
        return []
    }
}

private enum ReverseProtocolWitnessableError: Error, CustomStringConvertible {
    case noProtocolAllowed
    
    var description: String {
        "@ReverseProtocolWitnessable cannot be attached to protocols"
    }
}
