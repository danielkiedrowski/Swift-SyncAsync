//
//  https://github.com/Kametrixom/Swift-SyncAsync/
//

import Foundation

// MARK: Utils -

private struct Group {
    let group = DispatchGroup()
    func enter() { group.enter() }
    func leave() { group.leave() }
    func wait() { _ = group.wait(timeout: .distantFuture) }
}

private func createConcurrent() -> DispatchQueue {
    return DispatchQueue(label: "", attributes: .concurrent)
}

private func async(_ queue: DispatchQueue, closure: @escaping () -> Void) {
    queue.async(execute: closure)
}

// MARK: - toAsync -

// MARK: No Error

public func toAsync<O>(_ f: @escaping () -> O) -> (_ completionHandler: @escaping (O) -> ()) -> () {
    let queue = createConcurrent()	// Needs to be concurrent because the method can be called multiple times
    return { ch in async(queue) { ch(f()) } }
}
public func toAsync<I0, O>(_ f: @escaping (I0) -> O) -> (I0, _ completionHandler: @escaping (O) -> ()) -> () {
    let queue = createConcurrent()
    return { i0, ch in async(queue) { ch(f(i0)) } }
}
public func toAsync<I0, I1, O>(_ f: @escaping (I0, I1) -> O) -> (I0, I1, _ completionHandler: @escaping (O) -> ()) -> () {
    let queue = createConcurrent()
    return { i0, i1, ch in async(queue) { ch(f(i0, i1)) } }
}
public func toAsync<I0, I1, I2, O>(_ f: @escaping (I0, I1, I2) -> O) -> (I0, I1, I2, _ completionHandler: @escaping (O) -> ()) -> () {
    let queue = createConcurrent()
    return { i0, i1, i2, ch in async(queue) { ch(f(i0, i1, i2)) } }
}
public func toAsync<I0, I1, I2, I3, O>(_ f: @escaping (I0, I1, I2, I3) -> O) -> (I0, I1, I2, I3, _ completionHandler: @escaping (O) -> ()) -> () {
    let queue = createConcurrent()
    return { i0, i1, i2, i3, ch in async(queue) { ch(f(i0, i1, i2, i3)) } }
}

// MARK: - Error

public func toAsync<O>(_ f: @escaping () throws -> O) -> (_ completionHandler: @escaping (O) -> (), _ errorHandler: @escaping (Error) -> ()) -> () {
    let queue = createConcurrent()
    return { ch, eh in async(queue) { do { try ch(f()) } catch { eh(error) } } }
}
public func toAsync<I0, O>(_ f: @escaping (I0) throws -> O) -> (I0, _ completionHandler: @escaping (O) -> (), _ errorHandler: @escaping (Error) -> ()) -> () {
    let queue = createConcurrent()
    return { i0, ch, eh in async(queue) { do { try ch(f(i0)) } catch { eh(error) } } }
}
public func toAsync<I0, I1, O>(_ f: @escaping (I0, I1) throws -> O) -> (I0, I1, _ completionHandler: @escaping (O) -> (), _ errorHandler: @escaping (Error) -> ()) -> () {
    let queue = createConcurrent()
    return { i0, i1, ch, eh in async(queue) { do { try ch(f(i0, i1)) } catch { eh(error) } } }
}
public func toAsync<I0, I1, I2, O>(_ f: @escaping (I0, I1, I2) throws -> O) -> (I0, I1, I2, _ completionHandler: @escaping (O) -> (), _ errorHandler: @escaping (Error) -> ()) -> () {
    let queue = createConcurrent()
    return { i0, i1, i2, ch, eh in async(queue) { do { try ch(f(i0, i1, i2)) } catch { eh(error) } } }
}
public func toAsync<I0, I1, I2, I3, O>(_ f: @escaping (I0, I1, I2, I3) throws -> O) -> (I0, I1, I2, I3, _ completionHandler: @escaping (O) -> (), _ errorHandler: @escaping (Error) -> ()) -> () {
    let queue = createConcurrent()
    return { i0, i1, i2, i3, ch, eh in async(queue) { do { try ch(f(i0, i1, i2, i3)) } catch { eh(error) } } }
}

// MARK: - toSync -

// MARK: No Error

public func toSync<I, O, R>(_ f: @escaping (I, _ completionHandler: @escaping (O) -> ()) -> R, start: @escaping (R) -> () = { _ in }) -> (I) -> O {
    return { input in
        let group = Group()
        var output: O!
        
        group.enter()
        start(f(input) {
            output = $0
            group.leave()
        })
        
        group.wait()
        return output
    }
}

public func toSync<O, R>(_ f: @escaping (_ completionHandler: @escaping (O) -> ()) -> R, start: @escaping (R) -> () = { _ in }) -> () -> O {
    return toSync({ (_, ch: @escaping ((O)->())) in return f(ch) }, start: start)
}
public func toSync<I0, I1, O, R>(_ f: @escaping (I0, I1, _ completionHandler: @escaping (O) -> ()) -> (R), start: @escaping (R) -> () = { _ in }) -> (I0, I1) -> O {
    return toSync({ f($0.0, $0.1, $1) }, start: start)
}
public func toSync<I0, I1, I2, O, R>(_ f: @escaping (I0, I1, I2, _ completionHandler: @escaping (O) -> ()) -> R, start: @escaping (R) -> () = { _ in }) -> (I0, I1, I2) -> O {
    return toSync({ f($0.0, $0.1, $0.2, $1) }, start: start)
}
public func toSync<I0, I1, I2, I3, O, R>(_ f: @escaping (I0, I1, I2, I3, _ completionHandler: @escaping (O) -> ()) -> R, start: @escaping (R) -> () = { _ in }) -> (I0, I1, I2, I3) -> O {
    return toSync({ f($0.0, $0.1, $0.2, $0.3, $1) }, start: start)
}

// MARK: - Error

// MARK: Error Handler

public func toSync<I, O, R>(_ f: @escaping (I, _ completionHandler: @escaping (O) -> Void, _ errorHandler: @escaping (Error) -> Void) -> R, start: @escaping (R) -> () = {_ in }) -> (I) throws -> O {
    return { i0 in
        let group = Group()
        var error: Error?, output: O!
        
        group.enter()
        start(f(i0, {
            output = $0
            group.leave()
        }, {
            error = $0
            group.leave()
        }))
        group.wait()
        
        if let error = error { throw error }
        return output
    }
}

public func toSync<I, O, R, E: Error>(_ f: @escaping (I, _ completionHandler: @escaping (O) -> Void, _ errorHandler: @escaping (E) -> Void) -> R, start: @escaping (R) -> () = {_ in }) -> (I) throws -> O {
    return { i0 in
        let group = Group()
        var error: E?, output: O!
        
        group.enter()
        start(f(i0, {
            output = $0
            group.leave()
        }, {
            error = $0
            group.leave()
        }))
        group.wait()
        
        if let error = error { throw error }
        return output
    }
}

public func toSync<O, R>(_ f: @escaping (_ completionHandler: @escaping (O) -> (), _ errorHandler: @escaping (Error) -> ()) -> R, start: @escaping (R) -> () = {_ in }) -> () throws -> O {
    return toSync({_, ch, eh in f(ch, eh) }, start: start)
}
public func toSync<O, R, E: Error>(_ f: @escaping (_ completionHandler: @escaping (O) -> Void, _ errorHandler: @escaping (E) -> Void) -> R, start: @escaping (R) -> () = {_ in }) -> (Void) throws -> O {
    return toSync({ _, ch, eh in f(ch, eh) }, start: start)
}
public func toSync<I1, I2, O, R>(_ f: @escaping (I1, I2, _ completionHandler: @escaping (O) -> Void, _ errorHandler: @escaping (Error) -> Void) -> R, start: @escaping (R) -> () = {_ in }) -> (I1, I2) throws -> O {
    return toSync({ i, ch, eh in f(i.0, i.1, ch, eh) }, start: start)
}
public func toSync<I1, I2, O, R, E: Error>(_ f: @escaping (I1, I2, _ completionHandler: @escaping (O) -> Void, _ errorHandler: @escaping (E) -> Void) -> R, start: @escaping (R) -> () = {_ in }) -> (I1, I2) throws -> O {
    return toSync({ i, ch, eh in f(i.0, i.1, ch, eh) }, start: start)
}
public func toSync<I1, I2, I3, O, R>(_ f: @escaping (I1, I2, I3, _ completionHandler: @escaping (O) -> Void, _ errorHandler: @escaping (Error) -> Void) -> R, start: @escaping (R) -> () = {_ in }) -> (I1, I2, I3) throws -> O {
    return toSync({ i, ch, eh in f(i.0, i.1, i.2, ch, eh) }, start: start)
}
public func toSync<I1, I2, I3, O, R, E: Error>(_ f: @escaping (I1, I2, I3, _ completionHandler: @escaping (O) -> Void, _ errorHandler: @escaping (E) -> Void) -> R, start: @escaping (R) -> () = {_ in }) -> (I1, I2, I3) throws -> O {
    return toSync({ i, ch, eh in f(i.0, i.1, i.2, ch, eh) }, start: start)
}
public func toSync<I1, I2, I3, I4, O, R>(_ f: @escaping (I1, I2, I3, I4, _ completionHandler: @escaping (O) -> Void, _ errorHandler: @escaping (Error) -> Void) -> R, start: @escaping (R) -> () = {_ in }) -> (I1, I2, I3, I4) throws -> O {
    return toSync({ i, ch, eh in f(i.0, i.1, i.2, i.3, ch, eh) }, start: start)
}
public func toSync<I1, I2, I3, I4, O, R, E: Error>(_ f: @escaping (I1, I2, I3, I4, _ completionHandler: @escaping (O) -> Void, _ errorHandler: @escaping (E) -> Void) -> R, start: @escaping (R) -> () = {_ in }) -> (I1, I2, I3, I4) throws -> O {
    return toSync({ i, ch, eh in f(i.0, i.1, i.2, i.3, ch, eh) }, start: start)
}

// MARK: No Error Handler

public func toSync<I, O, R>(_ f: @escaping (I, _ completionHandler: @escaping (O, Error?) -> ()) -> R, start: @escaping (R) -> () = { _ in }) -> (I) throws -> O {
    return { input in
        let group = Group()
        var error: Error?, output: O!
        
        group.enter()
        start(f(input) {
            (output, error) = ($0, $1)
            group.leave()
        })
        group.wait()
        
        if let error = error { throw error }
        return output
    }
}

public func toSync<I, O, R, E: Error>(_ f: @escaping (I, _ completionHandler: @escaping (O, E?) -> ()) -> R, start: @escaping (R) -> () = { _ in }) -> (I) throws -> O {
    return { input in
        let group = Group()
        var error: E?, output: O!
        
        group.enter()
        start(f(input) {
            (output, error) = ($0, $1)
            group.leave()
        })
        group.wait()
        
        if let error = error { throw error }
        return output
    }
}

public func toSync<I0, R>(_ f: @escaping (I0, _ completionHandler: @escaping (Error?) -> ()) -> R, start: @escaping (R) -> () = { _ in }) -> (I0) throws -> () {
    /*return toSync({ (i: I0, ch: (Void, Error?)->()) in
     return f(i) { (error: Error?) in
     ch((), error)
     }
     }, start: start)*/
    
    return toSync({ i, ch in f(i) { ch((), $0) } }, start: start)
}
public func toSync<I0, R, E: Error>(_ f: @escaping (I0, _ completionHandler: @escaping (E?) -> ()) -> R, start: @escaping (R) -> () = { _ in }) -> (I0) throws -> () {
    return toSync({ i, ch in f(i) { ch((), $0) } }, start: start)
}
public func toSync<I0, O0, O1, R>(_ f: @escaping (I0, _ completionHandler: @escaping (O0, O1, Error?) -> ()) -> R, start: @escaping (R) -> () = { _ in }) -> (I0) throws -> (O0, O1) {
    return toSync({ i, ch in f(i) { ch(($0, $1), $2) } }, start: start)
}
public func toSync<I0, O0, O1, R, E: Error>(_ f: @escaping (I0, _ completionHandler: @escaping (O0, O1, E?) -> ()) -> R, start: @escaping (R) -> () = { _ in }) -> (I0) throws -> (O0, O1) {
    return toSync({ i, ch in f(i) { ch(($0, $1), $2) } }, start: start)
}
public func toSync<I0, O0, O1, O2, R>(_ f: @escaping (I0, _ completionHandler: @escaping (O0, O1, O2, Error?) -> ()) -> R, start: @escaping (R) -> () = { _ in }) -> (I0) throws -> (O0, O1, O2) {
    return toSync({ i, ch in f(i) { ch(($0, $1, $2), $3) } }, start: start)
}
public func toSync<I0, O0, O1, O2, R, E: Error>(_ f: @escaping (I0, _ completionHandler: @escaping (O0, O1, O2, E?) -> ()) -> R, start: @escaping (R) -> () = { _ in }) -> (I0) throws -> (O0, O1, O2) {
    return toSync({ i, ch in f(i) { ch(($0, $1, $2), $3) } }, start: start)
}
public func toSync<I0, O0, O1, O2, O3, R>(_ f: @escaping (I0, _ completionHandler: @escaping (O0, O1, O2, O3, Error?) -> ()) -> R, start: @escaping (R) -> () = { _ in }) -> (I0) throws -> (O0, O1, O2, O3) {
    return toSync({ i, ch in f(i) { ch(($0, $1, $2, $3), $4) } }, start: start)
}
public func toSync<I0, O0, O1, O2, O3, R, E: Error>(_ f: @escaping (I0, _ completionHandler: @escaping (O0, O1, O2, O3, E?) -> ()) -> R, start: @escaping (R) -> () = { _ in }) -> (I0) throws -> (O0, O1, O2, O3) {
    return toSync({ i, ch in f(i) { ch(($0, $1, $2, $3), $4) } }, start: start)
}

public func toSync<R>(_ f: @escaping (_ completionHandler: @escaping (Error?) -> ()) -> R, start: @escaping (R) -> () = { _ in }) -> () throws -> () {
    return toSync({ i, ch in f(ch) }, start: start)
}
public func toSync<R, E: Error>(_ f: @escaping (_ completionHandler: @escaping (E?) -> ()) -> R, start: @escaping (R) -> () = { _ in }) -> () throws -> () {
    return toSync({ i, ch in f(ch) }, start: start)
}
public func toSync<I0, I1, R>(_ f: @escaping (I0, I1, _ completionHandler: @escaping (Error?) -> ()) -> R, start: @escaping (R) -> () = { _ in }) -> (I0, I1) throws -> () {
    return toSync({ i, ch in f(i.0, i.1, ch) }, start: start)
}
public func toSync<I0, I1, R, E: Error>(_ f: @escaping (I0, I1, _ completionHandler: @escaping (E?) -> ()) -> R, start: @escaping (R) -> () = { _ in }) -> (I0, I1) throws -> () {
    return toSync({ i, ch in f(i.0, i.1, ch) }, start: start)
}
public func toSync<I0, I1, I2, R>(_ f: @escaping (I0, I1, I2, _ completionHandler: @escaping (Error?) -> ()) -> R, start: @escaping (R) -> () = { _ in }) -> (I0, I1, I2) throws -> () {
    return toSync({ i, ch in f(i.0, i.1, i.2, ch) }, start: start)
}
public func toSync<I0, I1, I2, R, E: Error>(_ f: @escaping (I0, I1, I2, _ completionHandler: @escaping (E?) -> ()) -> R, start: @escaping (R) -> () = { _ in }) -> (I0, I1, I2) throws -> () {
    return toSync({ i, ch in f(i.0, i.1, i.2, ch) }, start: start)
}
public func toSync<I0, I1, I2, I3, R>(_ f: @escaping (I0, I1, I2, I3, _ completionHandler: @escaping (Error?) -> ()) -> R, start: @escaping (R) -> () = { _ in }) -> (I0, I1, I2, I3) throws -> () {
    return toSync({ i, ch in f(i.0, i.1, i.2, i.3, ch) }, start: start)
}
public func toSync<I0, I1, I2, I3, R, E: Error>(_ f: @escaping (I0, I1, I2, I3, _ completionHandler: @escaping (E?) -> ()) -> R, start: @escaping (R) -> () = { _ in }) -> (I0, I1, I2, I3) throws -> () {
    return toSync({ i, ch in f(i.0, i.1, i.2, i.3, ch) }, start: start)
}

public func toSync<O0, R>(_ f: @escaping (_ completionHandler: @escaping (O0, Error?) -> ()) -> R, start: @escaping (R) -> () = { _ in }) -> () throws -> (O0) {
    return toSync({ i, ch in f(ch) }, start: start)
}
public func toSync<O0, R, E: Error>(_ f: @escaping (_ completionHandler: @escaping (O0, E?) -> ()) -> R, start: @escaping (R) -> () = { _ in }) -> () throws -> (O0) {
    return toSync({ i, ch in f(ch) }, start: start)
}
public func toSync<I0, I1, O0, R>(_ f: @escaping (I0, I1, _ completionHandler: @escaping (O0, Error?) -> ()) -> R, start: @escaping (R) -> () = { _ in }) -> (I0, I1) throws -> (O0) {
    return toSync({ i, ch in f(i.0, i.1, ch) }, start: start)
}
public func toSync<I0, I1, O0, R, E: Error>(_ f: @escaping (I0, I1, _ completionHandler: @escaping (O0, E?) -> ()) -> R, start: @escaping (R) -> () = { _ in }) -> (I0, I1) throws -> (O0) {
    return toSync({ i, ch in f(i.0, i.1, ch) }, start: start)
}
public func toSync<I0, I1, I2, O0, R>(_ f: @escaping (I0, I1, I2, _ completionHandler: @escaping (O0, Error?) -> ()) -> R, start: @escaping (R) -> () = { _ in }) -> (I0, I1, I2) throws -> (O0) {
    return toSync({ i, ch in f(i.0, i.1, i.2, ch) }, start: start)
}
public func toSync<I0, I1, I2, O0, R, E: Error>(_ f: @escaping (I0, I1, I2, _ completionHandler: @escaping (O0, E?) -> ()) -> R, start: @escaping (R) -> () = { _ in }) -> (I0, I1, I2) throws -> (O0) {
    return toSync({ i, ch in f(i.0, i.1, i.2, ch) }, start: start)
}
public func toSync<I0, I1, I2, I3, O0, R>(_ f: @escaping (I0, I1, I2, I3, _ completionHandler: @escaping (O0, Error?) -> ()) -> R, start: @escaping (R) -> () = { _ in }) -> (I0, I1, I2, I3) throws -> (O0) {
    return toSync({ i, ch in f(i.0, i.1, i.2, i.3, ch) }, start: start)
}
public func toSync<I0, I1, I2, I3, O0, R, E: Error>(_ f: @escaping (I0, I1, I2, I3, _ completionHandler: @escaping (O0, E?) -> ()) -> R, start: @escaping (R) -> () = { _ in }) -> (I0, I1, I2, I3) throws -> (O0) {
    return toSync({ i, ch in f(i.0, i.1, i.2, i.3, ch) }, start: start)
}

public func toSync<O0, O1, R>(_ f: @escaping (_ completionHandler: @escaping (O0, O1, Error?) -> ()) -> R, start: @escaping (R) -> () = { _ in }) -> () throws -> (O0, O1) {
    return toSync({ i, ch in f(ch) }, start: start)
}
public func toSync<O0, O1, R, E: Error>(_ f: @escaping (_ completionHandler: @escaping (O0, O1, E?) -> ()) -> R, start: @escaping (R) -> () = { _ in }) -> () throws -> (O0, O1) {
    return toSync({ i, ch in f(ch) }, start: start)
}
public func toSync<I0, I1, O0, O1, R>(_ f: @escaping (I0, I1, _ completionHandler: @escaping (O0, O1, Error?) -> ()) -> R, start: @escaping (R) -> () = { _ in }) -> (I0, I1) throws -> (O0, O1) {
    return toSync({ i, ch in f(i.0, i.1, ch) }, start: start)
}
public func toSync<I0, I1, O0, O1, R, E: Error>(_ f: @escaping (I0, I1, _ completionHandler: @escaping (O0, O1, E?) -> ()) -> R, start: @escaping (R) -> () = { _ in }) -> (I0, I1) throws -> (O0, O1) {
    return toSync({ i, ch in f(i.0, i.1, ch) }, start: start)
}
public func toSync<I0, I1, I2, O0, O1, R>(_ f: @escaping (I0, I1, I2, _ completionHandler: @escaping (O0, O1, Error?) -> ()) -> R, start: @escaping (R) -> () = { _ in }) -> (I0, I1, I2) throws -> (O0, O1) {
    return toSync({ i, ch in f(i.0, i.1, i.2, ch) }, start: start)
}
public func toSync<I0, I1, I2, O0, O1, R, E: Error>(_ f: @escaping (I0, I1, I2, _ completionHandler: @escaping (O0, O1, E?) -> ()) -> R, start: @escaping (R) -> () = { _ in }) -> (I0, I1, I2) throws -> (O0, O1) {
    return toSync({ i, ch in f(i.0, i.1, i.2, ch) }, start: start)
}
public func toSync<I0, I1, I2, I3, O0, O1, R>(_ f: @escaping (I0, I1, I2, I3, _ completionHandler: @escaping (O0, O1, Error?) -> ()) -> R, start: @escaping (R) -> () = { _ in }) -> (I0, I1, I2, I3) throws -> (O0, O1) {
    return toSync({ i, ch in f(i.0, i.1, i.2, i.3, ch) }, start: start)
}
public func toSync<I0, I1, I2, I3, O0, O1, R, E: Error>(_ f: @escaping (I0, I1, I2, I3, _ completionHandler: @escaping (O0, O1, E?) -> ()) -> R, start: @escaping (R) -> () = { _ in }) -> (I0, I1, I2, I3) throws -> (O0, O1) {
    return toSync({ i, ch in f(i.0, i.1, i.2, i.3, ch) }, start: start)
}

public func toSync<O0, O1, O2, R>(_ f: @escaping (_ completionHandler: @escaping (O0, O1, O2, Error?) -> ()) -> R, start: @escaping (R) -> () = { _ in }) -> () throws -> (O0, O1, O2) {
    return toSync({ i, ch in f(ch) }, start: start)
}
public func toSync<O0, O1, O2, R, E: Error>(_ f: @escaping (_ completionHandler: @escaping (O0, O1, O2, E?) -> ()) -> R, start: @escaping (R) -> () = { _ in }) -> () throws -> (O0, O1, O2) {
    return toSync({ i, ch in f(ch) }, start: start)
}
public func toSync<I0, I1, O0, O1, O2, R>(_ f: @escaping (I0, I1, _ completionHandler: @escaping (O0, O1, O2, Error?) -> ()) -> R, start: @escaping (R) -> () = { _ in }) -> (I0, I1) throws -> (O0, O1, O2) {
    return toSync({ i, ch in f(i.0, i.1, ch) }, start: start)
}
public func toSync<I0, I1, O0, O1, O2, R, E: Error>(_ f: @escaping (I0, I1, _ completionHandler: @escaping (O0, O1, O2, E?) -> ()) -> R, start: @escaping (R) -> () = { _ in }) -> (I0, I1) throws -> (O0, O1, O2) {
    return toSync({ i, ch in f(i.0, i.1, ch) }, start: start)
}
public func toSync<I0, I1, I2, O0, O1, O2, R>(_ f: @escaping (I0, I1, I2, _ completionHandler: @escaping (O0, O1, O2, Error?) -> ()) -> R, start: @escaping (R) -> () = { _ in }) -> (I0, I1, I2) throws -> (O0, O1, O2) {
    return toSync({ i, ch in f(i.0, i.1, i.2, ch) }, start: start)
}
public func toSync<I0, I1, I2, O0, O1, O2, R, E: Error>(_ f: @escaping (I0, I1, I2, _ completionHandler: @escaping (O0, O1, O2, E?) -> ()) -> R, start: @escaping (R) -> () = { _ in }) -> (I0, I1, I2) throws -> (O0, O1, O2) {
    return toSync({ i, ch in f(i.0, i.1, i.2, ch) }, start: start)
}
public func toSync<I0, I1, I2, I3, O0, O1, O2, R>(_ f: @escaping (I0, I1, I2, I3, _ completionHandler: @escaping (O0, O1, O2, Error?) -> ()) -> R, start: @escaping (R) -> () = { _ in }) -> (I0, I1, I2, I3) throws -> (O0, O1, O2) {
    return toSync({ i, ch in f(i.0, i.1, i.2, i.3, ch) }, start: start)
}
public func toSync<I0, I1, I2, I3, O0, O1, O2, R, E: Error>(_ f: @escaping (I0, I1, I2, I3, _ completionHandler: @escaping (O0, O1, O2, E?) -> ()) -> R, start: @escaping (R) -> () = { _ in }) -> (I0, I1, I2, I3) throws -> (O0, O1, O2) {
    return toSync({ i, ch in f(i.0, i.1, i.2, i.3, ch) }, start: start)
}

public func toSync<O0, O1, O2, O3, R>(_ f: @escaping (_ completionHandler: @escaping (O0, O1, O2, O3, Error?) -> ()) -> R, start: @escaping (R) -> () = { _ in }) -> () throws -> (O0, O1, O2, O3) {
    return toSync({ i, ch in f(ch) }, start: start)
}
public func toSync<O0, O1, O2, O3, R, E: Error>(_ f: @escaping (_ completionHandler: @escaping (O0, O1, O2, O3, E?) -> ()) -> R, start: @escaping (R) -> () = { _ in }) -> () throws -> (O0, O1, O2, O3) {
    return toSync({ i, ch in f(ch) }, start: start)
}
public func toSync<I0, I1, O0, O1, O2, O3, R>(_ f: @escaping (I0, I1, _ completionHandler: @escaping (O0, O1, O2, O3, Error?) -> ()) -> R, start: @escaping (R) -> () = { _ in }) -> (I0, I1) throws -> (O0, O1, O2, O3) {
    return toSync({ i, ch in f(i.0, i.1, ch) }, start: start)
}
public func toSync<I0, I1, O0, O1, O2, O3, R, E: Error>(_ f: @escaping (I0, I1, _ completionHandler: @escaping (O0, O1, O2, O3, E?) -> ()) -> R, start: @escaping (R) -> () = { _ in }) -> (I0, I1) throws -> (O0, O1, O2, O3) {
    return toSync({ i, ch in f(i.0, i.1, ch) }, start: start)
}
public func toSync<I0, I1, I2, O0, O1, O2, O3, R>(_ f: @escaping (I0, I1, I2, _ completionHandler: @escaping (O0, O1, O2, O3, Error?) -> ()) -> R, start: @escaping (R) -> () = { _ in }) -> (I0, I1, I2) throws -> (O0, O1, O2, O3) {
    return toSync({ i, ch in f(i.0, i.1, i.2, ch) }, start: start)
}
public func toSync<I0, I1, I2, O0, O1, O2, O3, R, E: Error>(_ f: @escaping (I0, I1, I2, _ completionHandler: @escaping (O0, O1, O2, O3, E?) -> ()) -> R, start: @escaping (R) -> () = { _ in }) -> (I0, I1, I2) throws -> (O0, O1, O2, O3) {
    return toSync({ i, ch in f(i.0, i.1, i.2, ch) }, start: start)
}
public func toSync<I0, I1, I2, I3, O0, O1, O2, O3, R>(_ f: @escaping (I0, I1, I2, I3, _ completionHandler: @escaping (O0, O1, O2, O3, Error?) -> ()) -> R, start: @escaping (R) -> () = { _ in }) -> (I0, I1, I2, I3) throws -> (O0, O1, O2, O3) {
    return toSync({ i, ch in f(i.0, i.1, i.2, i.3, ch) }, start: start)
}
public func toSync<I0, I1, I2, I3, O0, O1, O2, O3, R, E: Error>(_ f: @escaping (I0, I1, I2, I3, _ completionHandler: @escaping (O0, O1, O2, O3, E?) -> ()) -> R, start: @escaping (R) -> () = { _ in }) -> (I0, I1, I2, I3) throws -> (O0, O1, O2, O3) {
    return toSync({ i, ch in f(i.0, i.1, i.2, i.3, ch) }, start: start)
}
