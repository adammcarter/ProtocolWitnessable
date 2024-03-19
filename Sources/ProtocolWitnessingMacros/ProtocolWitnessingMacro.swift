import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros


@main
struct ProtocolWitnessingPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        WitnessingMacro.self,
    ]
}



public struct WitnessingMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let structDecl = declaration as? StructDeclSyntax else {
            throw WitnessingError.structOnly
        }
        
        
        
        let functions = structDecl.memberBlock.members
            .compactMap { $0.decl.as(FunctionDeclSyntax.self) }
            .map {
                let parameterTypesList = $0
                    .signature
                    .parameterClause
                    .parameters
                    .compactMap {
                        $0
                            .type
                            .as(IdentifierTypeSyntax.self)?
                            .name
                            .text
                    }
                    .joined(separator: ", ")
                
                let parameterNameWithTypeList = $0
                    .signature
                    .parameterClause
                    .parameters
                    .compactMap {
                        guard
                            let type = $0
                                .type
                                .as(IdentifierTypeSyntax.self)?
                                .name
                                .text
                        else {
                            return nil
                        }
                        
                        let firstName = $0.firstName.text

                        return "\(firstName): \(type)"
                    }
                    .joined(separator: ", ")
                
                let parameterNameWithNameList = $0
                    .signature
                    .parameterClause
                    .parameters
                    .compactMap { "\($0.firstName.text)" }
                    .joined(separator: ", ")
                
                
                
                
                
                let returnValue = $0
                    .signature
                    .returnClause?
                    .type
                    .as(IdentifierTypeSyntax.self)?
                    .name
                    .text
                
                let name = $0.name.text
                
                let returnValueOrVoid = returnValue ?? "Void"
                let returnValueIfNotVoid = returnValue.flatMap { " -> \($0)" } ?? ""
                
                
                
                
                
                return FunctionDetails(
                    name: name,
                    type: "(\(parameterTypesList)) -> \(returnValueOrVoid)",
                    callsite:
                        """
                        func \(name)(\(parameterNameWithTypeList))\(returnValueIfNotVoid) {
                        _\(name)(\(parameterNameWithNameList))
                        }
                        """
                )
            }
        
        
        
        let expandedProperties = functions
            .map {
                "var _\($0.name): \($0.type)"
            }
            .joined(separator: "\n")
        
        
        
        
        
        
        
        let expandedInit: String
        
        if functions.isEmpty {
            expandedInit = 
                """
                init() {
                
                }
                """
        } else if functions.count == 1, let function = functions.first {
            expandedInit = 
                """
                init(\(function.name): @escaping \(function.type)) {
                _\(function.name) = \(function.name)
                }
                """
        } else {
            let args = functions
                .map { "\($0.name): @escaping \($0.type)" }
                .joined(separator: ",\n")
            
            let assigns = functions
                .map { "_\($0.name) = \($0.name)" }
                .joined(separator: "\n")
            
            expandedInit = 
                """
                init(
                \(args)
                ) {
                \(assigns)
                }
                """
        }
        
        
        
        
        
        
        let expandedFunctions = functions
            .map {
                $0.callsite
            }
            .joined(separator: "\n\n")
        
        
        
        
        
        
        let witnessDecl: DeclSyntax
        
        if expandedProperties.isEmpty {
            witnessDecl = """
                struct Witness {
                    \(raw: expandedInit)
                }
                """
        } else {
            witnessDecl = """
                struct Witness {
                    \(raw: expandedProperties)
                    
                    \(raw: expandedInit)
                    
                    \(raw: expandedFunctions)
                }
                """
        }
        
        return [witnessDecl]
    }
}


private struct FunctionDetails {
    let name: String
    let type: String
    let callsite: String
}

private enum WitnessingError: Error, CustomStringConvertible {
    case structOnly
    
    var description: String {
        switch self {
            case .structOnly: "@Witnessing can only be attached to a struct"
        }
    }
}
