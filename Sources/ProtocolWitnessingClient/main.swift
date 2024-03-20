import ProtocolWitnessing

// TODO: 

// @Witnessing(_ typeName: String = "Witness", generatedRealName: String? = "production")
//@Witnessing
////@Witnessing("ChildWitness")
//struct MyService {
//    func fetchData() -> Int {
//        return (100...10_000).randomElement()!
//    }
//    
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
//
//var mock = MyComplexClient.production
//mock._somethingThatDownloadsData = { int, completion in
//    debugPrint(int)
//    
//    let test = [
//        CodedThing(name: "test", age: 999),
//    ]
//    
//    completion(test)
//}
//
//mock.somethingThatDownloadsData(int: 0) { things in
//    print(things)
//}
//
//Thread.sleep(forTimeInterval: 10)
//
//
//
