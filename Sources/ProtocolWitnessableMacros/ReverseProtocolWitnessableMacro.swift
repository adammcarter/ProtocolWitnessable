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
        
        guard let prefix = makeProtocolPrefix(from: declaration) else {
            throw ReverseProtocolWitnessableError.missingTypeName
        }
        
        let name = makeProtocolName(prefix: prefix)
        let capturedProperties = makeCapturedProperties(from: declaration)
        
        let capturedPropertiesAsProperties = capturedProperties
            .map {
                let getSet = $0.isLet ? "get" : "get set"
                
                return "var \($0.name): \($0.type) { \(getSet) }"
            }
        
        let propertiesString = capturedPropertiesAsProperties.isEmpty
            ? ""
            : "\n\(capturedPropertiesAsProperties.joined(separator: "\n\n"))"
        
        return [
            makeProtocolDeclaration(
                name: name,
                propertiesString: propertiesString
            )
        ]
    }
}


// MARK: - Declarations

private func makeProtocolDeclaration(
    name: String,
    propertiesString: String
) -> DeclSyntax {
    DeclSyntax(stringLiteral: """
        @ProtocolWitnessable
        protocol \(name) {\(propertiesString)
        }
        """
    )
}


// MARK: - Helpers

private func makeProtocolPrefix(from declSyntax: some DeclSyntaxProtocol) -> String? {
    declSyntax.as(StructDeclSyntax.self)?.name.trimmedDescription
}

private func makeProtocolName(prefix: String) -> String {
    "\(prefix)ReverseProtocolWitness"
}


// MARK: - Types

private enum ReverseProtocolWitnessableError: Error, CustomStringConvertible {
    case noProtocolAllowed
    case missingTypeName
    
    var description: String {
        switch self {
            case .noProtocolAllowed: "@ReverseProtocolWitnessable cannot be attached to protocols"
            case .missingTypeName: "No type name to make a protocol from"
        }
    }
}
