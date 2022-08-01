// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKit/

import AVFAudio

public enum NodeConnectStrategy {
    /// Recursive strategy enumerates Node connections
    /// and performs AVAudioEngine connections in a BFS order.
    /// This can sometimes result in an incorrectly wired engine graph.
    case recursive
    /// Optimised strategy enumerates Node connections recursively
    /// but instead of making AVAudionEngine connections,
    /// they are only collected.
    /// Once all connections are resolved, AVAudioEngine connections are made
    /// in a strict order from source to destination nodes.
    case optimised
}

extension Node {
    func makeAVConnections(strategy: NodeConnectStrategy) {
        switch strategy {
        case .recursive: makeAVConnectionsRecursive()
        case .optimised: makeAVConnectionsOptimised()
        }
    }
}

private extension Node {

    func makeAVConnectionsOptimised() {
        guard let engine = avAudioNode.engine else { return }
        var connections: [AVAudioNode: ([AVAudioConnectionPoint], AVAudioFormat)] = [:]
        makeOptimised(connectionsToMake: &connections)

        // We need to do this in a strict order, from source to destination nodes
        // Otherwise, the result will be a broken graph.
        while let (node, points, format) = findNodeWithoutInputs(in: connections) {
            let transformedPoints = points.map { point -> AVAudioConnectionPoint in
                guard let mixer = point.node as? AVAudioMixerNode else { return point }
                return AVAudioConnectionPoint(node: mixer, bus: mixer.nextAvailableInputBus)
            }
            engine.connect(node, to: transformedPoints, fromBus: 0, format: format)
            connections.removeValue(forKey: node)
        }
    }

    func findNodeWithoutInputs(
        in connections: [AVAudioNode: ([AVAudioConnectionPoint], AVAudioFormat)]
    ) -> (AVAudioNode, [AVAudioConnectionPoint], AVAudioFormat)? {
        let nodesWithInput = connections.flatMap(\.value.0).compactMap(\.node)
        guard let (node, (points, format)) = connections.first(where: {
            nodesWithInput.doesNotContain($0.key)
        }) else { return nil }
        return (node, points, format)
    }

    func makeOptimised(
        connectionsToMake: inout [AVAudioNode: ([AVAudioConnectionPoint], AVAudioFormat)]
    ) {
        (self as? HasInternalConnections)?.makeInternalConnections()
        guard let engine = avAudioNode.engine else { return }
        for (bus, connection) in connections.enumerated() {
            if let sourceEngine = connection.avAudioNode.engine {
                if sourceEngine != avAudioNode.engine {
                    Log("🛑 Error: Attempt to connect nodes from different engines.")
                    return
                }
            }

            engine.attach(connection.avAudioNode)

            let existing = connectionsToMake[connection.avAudioNode]?.0 ?? engine.outputConnectionPoints(for: connection.avAudioNode, outputBus: 0)
            if !existing.contains(where: { $0.node === avAudioNode }) {
                let new = existing + [AVAudioConnectionPoint(node: avAudioNode, bus: bus)]
                connectionsToMake[connection.avAudioNode] = (new, connection.outputFormat)
            }
            connection.makeOptimised(connectionsToMake: &connectionsToMake)
        }
    }

    func makeAVConnectionsRecursive() {
        (self as? HasInternalConnections)?.makeInternalConnections()

        // Are we attached?
        guard let engine = avAudioNode.engine else { return }
        for (bus, connection) in connections.enumerated() {
            if let sourceEngine = connection.avAudioNode.engine {
                if sourceEngine != avAudioNode.engine {
                    Log("🛑 Error: Attempt to connect nodes from different engines.")
                    return
                }
            }
            engine.attach(connection.avAudioNode)

            // Mixers will decide which input bus to use.
            if let mixer = avAudioNode as? AVAudioMixerNode {
                mixer.connectMixer(input: connection.avAudioNode, format: connection.outputFormat)
            } else {
                avAudioNode.connect(input: connection.avAudioNode, bus: bus, format: connection.outputFormat)
            }
            connection.makeAVConnectionsRecursive()
        }
    }
}
