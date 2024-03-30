![example workflow](https://github.com/adamcarter93/ProtocolWitnessable/actions/workflows/swift.yml/badge.svg)


## Known issues

### Duplicate function names

#### Problem

Functions with the same opening function name but distinct signatures via different parameter names will conflict.

For example, the two functions below: 

```swift
func data(for request: URLRequest) async throws -> (Data, URLResponse)
func data(from url: URL) async throws -> (Data, URLResponse)
```
Will be expanded to:
```swift
var _data: (URLRequest) async throws -> (Data, URLResponse)
var _data: (URL) async throws -> (Data, URLResponse)
```
which will conflict because the two property names `_data` are the same and will throw a compiler error:
> ❌ Invalid redeclaration of '_data'

#### Workaround

Distinguish the function's opening names explicitly, eg, the above example can be turned in to:
```swift
func dataForRequest(_ request: URLRequest) async throws -> (Data, URLResponse)
func dataFromURL(_ url: URL) async throws -> (Data, URLResponse)
```
Which is expanded to:
```swift
var _dataForRequest: (URLRequest) async throws -> (Data, URLResponse)
var _dataFromURL: (URL) async throws -> (Data, URLResponse)
```
And leaves a happy compiler 🤖
