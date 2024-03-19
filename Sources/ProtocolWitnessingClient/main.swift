import ProtocolWitnessing

// TODO: 

// @Witnessing(typeName: String = "Witness", generatedRealName: String = "production")
struct MyService {
    func fetchData() -> Int {
        return (100...10_000).randomElement()!
    }
    
    // < Generated >
    // Uses typeName arg
    struct Witness {
        var _fetchData: () -> Int
        
        init(fetchData: @escaping () -> Int) {
            _fetchData = fetchData
        }
        
        func fetchData() -> Int {
            _fetchData()
        }
    }
    // < / Generated >
}


// < Generated >
extension MyService {
    // Uses generatedRealName arg with _ prefix
    private static var _production = {
        Self()
    }()
    
    // Uses generatedRealName and typeName args
    static var production = Witness(
        fetchData: _production.fetchData
    )
}
// < / Generated >





// Using the Macro...

var production = MyService.production

print(production.fetchData())

var preproduction = production
preproduction._fetchData = { 0 }

print(preproduction.fetchData())

var flakey = production
flakey._fetchData = { (0...1).randomElement()! }

print(flakey.fetchData())

//var crashing = production
//crashing._fetchData = { fatalError("Crashed! :(") }
//
//print(crashing.fetchData())
