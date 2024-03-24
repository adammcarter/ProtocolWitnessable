import ProtocolWitnessing




/*
    MAIN MACRO
 */


// Manually written


/*
 Rules for @ProtocolWitnessing:
 - Must be attached to a protocol - can this be validated? Maybe some if on the passed in type?
    - let p = MyClient.Protocol.self    <-- only protocols have this .Protocol so we can use that to check?
    - Alt can the argument's type be a protocol so swift compiler enforces only protocols are passed in
 
 */


@ProtocolWitnessing
public protocol MyClient {
    var name: String { get }
    var height: Double { get set }
    
    func doSomething(age: Int) -> Void
}




// < Generated >

public struct MyClientProtocolWitness: MyClient {
    public let name: String
    public var height: Double
    
    public func doSomething(age: Int) -> Void {
        _doSomething(age)
    }
    
    var _doSomething: (Int) -> Void
}

public extension MyClient {
    static func makeErasedProtocolWitness(
        name: String,
        height: Double,
        doSomething: @escaping (Int) -> Void
    ) -> MyClient {
        MyClientProtocolWitness(
            name: name,
            height: height,
            _doSomething: doSomething
        )
    }

    func makingProtocolWitness() -> MyClientProtocolWitness {
        MyClientProtocolWitness(
            name: name,
            height: height,
            _doSomething: doSomething
        )
    }
}

// </ Generated >







/*
    VENDING TYPES MACRO - COULD BE IN A SEPARATE MACRO PACKAGE
 */

/*
 Rules for @ProtocolVending:
 - Only static funcs that return a MyClient are valid on this type
 - MyClient must be a protocol - can this be validated? Maybe some if on the passed in type?
    - let p = MyClient.Protocol.self    <-- only protocols have this .Protocol so we can use that to check?
    - Alt can the argument's type be a protocol so swift compiler enforces only protocols are passed in

*/


// Manually written

//@ProtocolVending(MyClient.self)
public enum MyClientMaker {
    static func production() -> MyClient {
        MyClientProtocolWitness.makeErasedProtocolWitness(
            name: "Adam",
            height: 180,
            doSomething: { print($0) }
        )
    }
    
    static func preview() -> MyClient {
        var preview = production().makingProtocolWitness()
        preview._doSomething = { _ in
            print(987654321)
        }
        
        return preview
    }
    
    static func test() -> MyClient {
        MyClientProtocolWitness.makeErasedProtocolWitness(
            name: "Test",
            height: 999,
            doSomething: { _ in print("Test") }
        )
    }
}


// < Generated >

extension MyClient {
    typealias Make = MyClientMaker
}

// </ Generated >







/*
        USE OF MACRO(S)
 */

let prod = MyClient.Make.production()
prod.doSomething(age: 30)

var mock = prod.makingProtocolWitness()
mock._doSomething = { _ in
    print(10)
}

mock.doSomething(age: 65)


var test: MyClient
test = .Make.test()

test.doSomething(age: 23456)
