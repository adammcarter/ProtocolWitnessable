import SwiftCompilerPlugin
import SwiftSyntaxMacros


@main
struct ProtocolWitnessablePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ProtocolWitnessableMacro.self,
        ReverseProtocolWitnessableMacro.self,
    ]
}
