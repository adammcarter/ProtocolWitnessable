// The Swift Programming Language
// https://docs.swift.org/swift-book

/**
 A macro that creates Protocol Witnesses by generalising the properties and functions in to a protocol, then applying the ProtocolWitnessable macro to the generated protocol
 
 This is handy for creating protocol witnesses from existing types that can't be changed yourself like types in other frameworks or libraries.
 */
@attached(peer, names: suffixed(ReverseProtocolWitness))
public macro ReverseProtocolWitnessable() = #externalMacro(module: "ProtocolWitnessableMacros", type: "ProtocolWitnessableMacro")
