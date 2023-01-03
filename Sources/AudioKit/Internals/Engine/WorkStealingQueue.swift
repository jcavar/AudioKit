

import Foundation
import Atomics

public protocol DefaultInit {
    init()
}

/// Lock-free unbounded single-producer multiple-consumer queue.
///
/// This class implements the work stealing queue described in the paper,
/// "Correct and Efficient Work-Stealing for Weak Memory Models,"
/// available at https://www.di.ens.fr/~zappa/readings/ppopp13.pdf.
///
/// Only the queue owner can perform pop and push operations,
/// while others can steal data from the queue.
/// Ported to swift from C++: https://github.com/taskflow/work-stealing-queue
public class WorkStealingQueue<T> where T: AtomicValue, T: DefaultInit {

    final class QueueArray: AtomicReference {

        var C: Int
        var M: Int

        var S: UnsafeMutableBufferPointer<ManagedAtomic<T>>

        init(_ c: Int) {
            C = c
            M = c-1
            S = UnsafeMutableBufferPointer<ManagedAtomic<T>>.allocate(capacity: c)
            _ = S.initialize(from: (0..<c).map { _ in ManagedAtomic(T()) })
        }

        var capacity: Int { C }

        func push(_ i: Int, _ o: T) {
            S[i & M].store(o, ordering: .relaxed)
        }

        func pop(_ i: Int) -> T {
            S[i & M].load(ordering: .relaxed)
        }

        func resize(_ b: Int, _ t: Int) -> QueueArray {
            let new = QueueArray(2*C)
            for i in t ..< b {
                new.push(i, pop(i))
            }
            return new
        }

    }

    var _top: ManagedAtomic<Int> = .init(0)
    var _bottom: ManagedAtomic<Int> = .init(0)
    var _array: ManagedAtomic<QueueArray>
    var _garbage: [QueueArray] = []

    /// constructs the queue with a given capacity
    ///
    /// capacity the capacity of the queue (must be power of 2)
    public init(capacity c: Int = 1024) {
        // assert(c && (!(c & (c-1))))
        _array = .init(QueueArray(c))
        _garbage.reserveCapacity(32)
    }

    /// queries if the queue is empty at the time of this call
    public var isEmpty: Bool {
        let b = _bottom.load(ordering: .relaxed)
        let t = _top.load(ordering: .relaxed)
        return b <= t
    }

    /// queries the number of items at the time of this call
    public var count: Int {
        let b = _bottom.load(ordering: .relaxed)
        let t = _top.load(ordering: .relaxed)
        return b >= t ? b - t : 0
    }

    /// queries the capacity of the queue
    public var capacity: Int {
        _array.load(ordering: .relaxed).capacity
    }

    /// inserts an item to the queue
    ///
    /// Only the owner thread can insert an item to the queue.
    /// The operation can trigger the queue to resize its capacity
    /// if more space is required.
    public func push(_ o: T) {
        let b = _bottom.load(ordering: .relaxed)
        let t = _top.load(ordering: .acquiring)
        var a = _array.load(ordering: .relaxed)

        // queue is full
        if a.capacity - 1 < (b - t) {
            var tmp = a.resize(b, t)
            _garbage.append(a)
            swap(&a, &tmp)
            _array.store(a, ordering: .relaxed)
        }

        a.push(b, o)
        atomicMemoryFence(ordering: .releasing)
        _bottom.store(b + 1, ordering: .relaxed)
    }

    /// pops out an item from the queue
    ///
    /// Only the owner thread can pop out an item from the queue.
    /// The return can be a @std_nullopt if this operation failed (empty queue).
    public func pop() -> T? {
        let b = _bottom.load(ordering: .relaxed) - 1
        let a = _array.load(ordering: .relaxed)
        _bottom.store(b, ordering: .relaxed)
        atomicMemoryFence(ordering: .sequentiallyConsistent)
        let t = _top.load(ordering: .relaxed)

        var item: T?

        if t <= b {
            item = a.pop(b)
            if t == b {
                // the last item just got stolen
                let (exchanged, _) = _top.compareExchange(expected: t,
                                                          desired: t+1,
                                                          successOrdering: .sequentiallyConsistent,
                                                          failureOrdering: .relaxed)
                if !exchanged {
                    item = nil
                }
                _bottom.store(b + 1, ordering: .relaxed)
            }
        } else {
            _bottom.store(b + 1, ordering: .relaxed)
        }

        return item
    }

    /// steals an item from the queue
    ///
    /// Any threads can try to steal an item from the queue.
    /// The return can be nil if this operation failed (not necessary empty).
    public func steal() -> T? {
        let t = _top.load(ordering: .acquiring)
        atomicMemoryFence(ordering: .sequentiallyConsistent)
        let b = _bottom.load(ordering: .acquiring)

        var item: T?

        if(t < b) {
            let a = _array.load(ordering: .acquiring)
            item = a.pop(t)

            let (exchanged, _) = _top.compareExchange(expected: t,
                                                      desired: t+1,
                                                      successOrdering: .sequentiallyConsistent,
                                                      failureOrdering: .relaxed)

            if !exchanged {
                return nil
            }
        }

        return item
    }
}