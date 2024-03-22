import ProtocolWitnessing

// TODO: 

// @ProtocolWitnessing(_ typeName: String = "Witness", generatedRealName: String? = "production")
//@ProtocolWitnessing
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
//@ProtocolWitnessing

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
//    
//    struct Witness {
//        var _somethingThatDownloadsData: (Int, @escaping ([CodedThing]) -> Void) -> Void
//        
//        init(somethingThatDownloadsData: @escaping (Int, @escaping ([CodedThing]) -> Void) -> Void) {
//            _somethingThatDownloadsData = somethingThatDownloadsData
//        }
//        
//        func somethingThatDownloadsData(int: Int, completion: @escaping ([CodedThing]) -> Void) {
//            _somethingThatDownloadsData(int, completion)
//        }
//    }
//}
//
//extension MyComplexClient {
//    private static var _production: MyComplexClient?
//    
//    static func production() -> MyComplexClient.Witness {
//        let production = _production ?? MyComplexClient()
//        
//        if _production == nil {
//            _production = production
//        }
//        
//        return MyComplexClient.Witness(
//            somethingThatDownloadsData: production.somethingThatDownloadsData
//        )
//    }
//    
//    func witness() -> Witness {
//        MyComplexClient.Witness(
//            somethingThatDownloadsData: somethingThatDownloadsData
//        )
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
//var mock = prod.witness()
//mock._somethingThatDownloadsData = { _, _ in
//    print("Hi from _somethingThatDownloadsData mock")
//}
//
//mock.somethingThatDownloadsData(int: 3) { things in
//    print("mock", things)
//}

//Thread.sleep(forTimeInterval: 10)

struct MyClient {
    var isAsync: Bool {
        get async {
            true
        }
    }
    
    struct ProtocolWitness {
        var _isAsync: Bool
        
        var isAsync: Bool {
            get async {
                _isAsync
            }
        }
        
        init(isAsync: Bool) {
            _isAsync = isAsync
        }
        
        
        
        private static var _production: MyClient?
        
        static func production() async -> MyClient.ProtocolWitness {
            let production = _production ?? MyClient()
            
            if _production == nil {
                _production = production
            }
            
            return MyClient.ProtocolWitness(
                isAsync: await production.isAsync
            )
        }
    }
}



//var prod = await MyClient.production(someLetProperty: 4)
//prod._someLetProperty = 4
//
//
//var mock = prod
//mock.some = true
//
//mock.somethingThatDownloadsData(int: 3) { things in
//    print("mock", things)
//}
