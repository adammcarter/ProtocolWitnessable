// The Swift Programming Language
// https://docs.swift.org/swift-book

/// A macro that produces a protocol witness from the types functions
@attached(member, names: named(init()))
@attached(member, names: arbitrary)
public macro Witnessing() = #externalMacro(module: "ProtocolWitnessingMacros", type: "WitnessingMacro")
