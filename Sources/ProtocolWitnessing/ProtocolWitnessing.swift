// The Swift Programming Language
// https://docs.swift.org/swift-book

/// A macro that produces a protocol witness from the types functions
@attached(peer, names: suffixed(ProtocolWitness))
public macro ProtocolWitnessing() = #externalMacro(module: "ProtocolWitnessingMacros", type: "WitnessingMacro")
