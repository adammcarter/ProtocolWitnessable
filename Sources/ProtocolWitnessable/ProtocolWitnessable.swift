// The Swift Programming Language
// https://docs.swift.org/swift-book

/**
 A macro that creates Protocol Witnesses by implementing it on a new struct type to be able to override get only properties and function definitions.
 
 This is handy for creating multiple instances that conform to a common interface without the constraints of protocols.
 
 It's common to make multiple types for: production, SwiftUI previews, unit tests.
 */
@attached(peer, names: suffixed(ProtocolWitness))
public macro ProtocolWitnessable(targetType: ProtocolWitnessTargetType = .struct) = #externalMacro(module: "ProtocolWitnessableMacros", type: "ProtocolWitnessableMacro")

public enum ProtocolWitnessTargetType {
    case `struct`
    case `class`
}
