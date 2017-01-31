import Foundation

public func async(closure: @escaping () -> ()) {
    DispatchQueue(label: "Async", attributes: .concurrent).async {
        closure()
    }
}

public func waitABit() {
	Thread.sleep(forTimeInterval: 0.01)
}

