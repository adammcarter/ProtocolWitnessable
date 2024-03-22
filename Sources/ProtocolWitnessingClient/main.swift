import ProtocolWitnessing

// TODO: 

// @Witnessing(_ typeName: String = "Witness", generatedRealName: String? = "production")
//@Witnessing
//////@Witnessing("ChildWitness")
//struct MyService {
//    func fetchData() -> Int {
//        return (100...10_000).randomElement()!
//    }
//    
//    // < Generated >
//    // Uses typeName arg
////    struct Witness {
////        var _fetchData: () -> Int
////        
////        init(fetchData: @escaping () -> Int) {
////            _fetchData = fetchData
////        }
////        
////        func fetchData() -> Int {
////            _fetchData()
////        }
////    }
//    // < / Generated >
//}


// < Generated > (if generatedRealName not nil)
//extension MyService {
//    // Uses generatedRealName arg with _ prefix
//    private static var _production = {
//        Self()
//    }()
//    
//    // Uses generatedRealName and typeName args
//    static var production = Witness(
//        fetchData: _production.fetchData
//    )
//}
// < / Generated >





// Using the Macro...

//var production = MyService.production
//
//print(production.fetchData())
//
//var preproduction = production
//preproduction._fetchData = { 0 }
//
//print(preproduction.fetchData())
//
//var flakey = production
//flakey._fetchData = { (0...1).randomElement()! }
//
//print(flakey.fetchData())

//var crashing = production
//crashing._fetchData = { fatalError("Crashed! :(") }
//
//print(crashing.fetchData())






//import Foundation
//
//@Witnessing
//struct MyComplexClient {
//    func somethingThatDownloadsData(int: Int, completion: @escaping ([CodedThing]) -> Void) {
//        let url = URL(string: "https://apple.com")!
//        
//        URLSession.shared.dataTask(with: .init(url: url)) { _, _, _ in
//            let json = [
//                [
//                    "name": "dndlsdn",
//                    "age": 43
//                ],
//                [
//                    "name": "gf",
//                    "age": 345
//                ],
//                [
//                    "name": "erg",
//                    "age": 876
//                ],
//            ]
//            
//            let data = try! JSONSerialization.data(withJSONObject: json)
//            
//            let things = try! JSONDecoder().decode([CodedThing].self, from: data)
//            
//            completion(things)
//        }.resume()
//    }
//}
//
//struct CodedThing: Codable {
//    let name: String
//    let age: Int
//}
//
//var prod = MyComplexClient.production()
//prod.somethingThatDownloadsData(int: 3) { things in
//    print("mock", things)
//}
//
//
//var mock = prod
//mock._somethingThatDownloadsData = { _, _ in
//    print("Hi from _somethingThatDownloadsData mock")
//}
//
//mock.somethingThatDownloadsData(int: 3) { things in
//    print("mock", things)
//}
//
//Thread.sleep(forTimeInterval: 10)


import Foundation

enum MyError: Error { case networkIssue }

@MainActor
class Thing {
    func doStuffHere() {
        print("Updating UI")
    }
}
@MainActor
struct MyClient {
    let id = UUID()
    var myThing: String
    let yourName: String
    
    func returnsTrue() -> Bool {
        true
    }
    
    func returnsVoid() async {
        print("doing async stuff for \(yourName)....")
        try? await Task.sleep(nanoseconds: 2 * NSEC_PER_SEC)
        print("async stuff done")
    }
    
    func returnsAThing() async throws -> Thing {
        throw MyError.networkIssue
    }
    
    struct Witness {
        var _myThing: String
        var _yourName: String
        var _returnsTrue: () -> Bool
        var _returnsVoid: () async -> Void
        var _returnsAThing: () async throws -> Thing
        
        var yourName: String {
            get {
                _yourName
            }
        }
        
        init(
            myThing: String,
            yourName: String,
            returnsTrue: @escaping () -> Bool,
            returnsVoid: @escaping () async -> Void,
            returnsAThing: @escaping () async throws -> Thing
        ) {
            _myThing = myThing
            _yourName = yourName
            _returnsTrue = returnsTrue
            _returnsVoid = returnsVoid
            _returnsAThing = returnsAThing
        }
        
        func returnsTrue() -> Bool {
            _returnsTrue()
        }
        
        func returnsVoid() async {
            await _returnsVoid()
        }
        
        func returnsAThing() async throws -> Thing {
            try await _returnsAThing()
        }
    }
}

extension MyClient {
    private static var _production: MyClient?
    
    static func production(
        myThing: String,
        yourName: String
    ) -> MyClient {
        let production = _production ?? MyClient(
            myThing: myThing,
            yourName: yourName
        )
        
        if _production == nil {
            _production = production
        }
        
        return production
    }
    
    func witness() -> MyClient.Witness {
        MyClient.Witness(
            myThing: myThing,
            yourName: yourName,
            returnsTrue: returnsTrue,
            returnsVoid: returnsVoid,
            returnsAThing: returnsAThing
        )
    }
}





import Foundation

await Task { @MainActor in
    let client = MyClient.production(myThing: "ddss", yourName: "prod")
    
    print(client.yourName)
    
    var mock = client.witness()
    mock._yourName = "mock"
    
    print(mock.yourName)
}.value


//var mock = client
//mock._doSomething = {
//    print("Mock. Async \(Thread.current)")
//}
//
//
//await mock.doSomething()


//print(client._som)
//var mock = client
//mock._someLetProperty = 9
//print(mock._someLetProperty)








//var prod = MyClient.live()
//prod.doSomething { int in
//    print(int)
//}
//
//
//var preprod = prod
//preprod._doSomething = { int in
//    print("preprod")
//}
//
//preprod.doSomething { int in
//    print("prod: \(int)")
//}
//
//
//var flakey = prod
//flakey._doSomething = { closure in
//    closure(Bool.random() ? 999 : -1)
//}
//
//flakey.doSomething { int in
//    print("Flakey \(int)")
//}
