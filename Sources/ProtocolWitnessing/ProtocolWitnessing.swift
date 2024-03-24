// The Swift Programming Language
// https://docs.swift.org/swift-book

/// A macro that produces a protocol witness from the types functions
@attached(member, names: arbitrary)
public macro ProtocolWitnessing() =
#externalMacro(module: "ProtocolWitnessingMacros", type: "WitnessingMacro")

@attached(member, names: arbitrary)
public macro ProtocolWitnessing(typeName: String) =
#externalMacro(module: "ProtocolWitnessingMacros", type: "WitnessingMacro")

@attached(member, names: arbitrary)
public macro ProtocolWitnessing(productionInstanceName: String) =
#externalMacro(module: "ProtocolWitnessingMacros", type: "WitnessingMacro")

@attached(member, names: arbitrary)
public macro ProtocolWitnessing(typeName: String, productionInstanceName: String) =
#externalMacro(module: "ProtocolWitnessingMacros", type: "WitnessingMacro")

@attached(member, names: arbitrary)
public macro ProtocolWitnessing(typeName: String, productionInstanceName: String, extraWitnessNames: [String]) =
#externalMacro(module: "ProtocolWitnessingMacros", type: "WitnessingMacro")
