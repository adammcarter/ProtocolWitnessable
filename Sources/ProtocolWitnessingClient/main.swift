import ProtocolWitnessing

// TODO: 

// @Witnessing(_ typeName: String = "Witness", generatedRealName: String? = "production")
@Witnessing
////@Witnessing("ChildWitness")
struct MyService {
    func fetchData() -> Int {
        return (100...10_000).randomElement()!
    }
    
    // < Generated >
    // Uses typeName arg
//    struct Witness {
//        var _fetchData: () -> Int
//        
//        init(fetchData: @escaping () -> Int) {
//            _fetchData = fetchData
//        }
//        
//        func fetchData() -> Int {
//            _fetchData()
//        }
//    }
    // < / Generated >
}


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





class Thing {}

@MainActor
struct MyClient {
    func returnsVoid() { }
    func returnsAThing() -> Thing { .init() }
    
    struct Witness {
        var _returnsVoid: () -> Void
        var _returnsAThing: () -> Thing
        
        init(
            returnsVoid: @escaping () -> Void,
            returnsAThing: @escaping () -> Thing
        ) {
            _returnsVoid = returnsVoid
            _returnsAThing = returnsAThing
        }
        
        func returnsVoid() {
            _returnsVoid()
        }
        
        func returnsAThing() -> Thing {
            _returnsAThing()
        }
    }
}

extension MyClient {
    private static var _production: MyClient?
    
    static func production() -> MyClient.Witness {
        let production = _production ?? MyClient()
        
        if _production == nil {
            _production = production
        }
        
        return MyClient.Witness(
            returnsVoid: production.returnsVoid,
            returnsAThing: production.returnsAThing
        )
    }
}



//import Foundation
//
//
//var client = try MyClient.production()
//
//print(try client.isAsync)
//
//var mock = client
//mock._isAsync = throw MyError.SomeThing
//
//print(try mock.isAsync)
//
//
//enum MyError: Error {
//    case SomeThing
//}


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
