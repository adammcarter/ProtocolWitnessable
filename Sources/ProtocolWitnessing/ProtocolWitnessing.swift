// The Swift Programming Language
// https://docs.swift.org/swift-book

/// A macro that produces a protocol witness from the types functions
@attached(member, names: arbitrary)
@attached(extension, names: arbitrary)
public macro Witnessing(_ typeName: String = "Witness", productionInstanceName: String = "production") =
    #externalMacro(module: "ProtocolWitnessingMacros", type: "WitnessingMacro")
