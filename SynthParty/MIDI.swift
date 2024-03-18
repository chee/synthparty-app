import CoreMIDI

public typealias UniqueID = MIDIUniqueID

public enum Error: Swift.Error {
    case osStatus(OSStatus)
    case invalidType
}

public enum Notification {
    case endpointAdded(MEndpoint)
    case endpointRemoved(MEndpoint)
    case other
}

public class MClient {
    public typealias Ref = MIDIClientRef
    
    public let ref: Ref
    
    public init(name: String, notifyBlock: @escaping (Notification) -> Void) throws {
        var clientRef = MIDIPortRef()
        let result = MIDIClientCreateWithBlock(name as CFString, &clientRef, { notificationPtr in
            let notification = notificationPtr.pointee
            switch notification.messageID {
            case .msgObjectAdded:
                let rawPtr = UnsafeRawPointer(notificationPtr)
                let message = rawPtr.assumingMemoryBound(to: MIDIObjectAddRemoveNotification.self).pointee
                if let type = MEndpointType(objectType: message.childType) {
                    let endpoint = MEndpoint(ref: message.child, type: type)
                    notifyBlock(.endpointAdded(endpoint))
                }
                
            case .msgObjectRemoved:
                let rawPtr = UnsafeRawPointer(notificationPtr)
                let message = rawPtr.assumingMemoryBound(to: MIDIObjectAddRemoveNotification.self).pointee
                if let type = MEndpointType(objectType: message.childType) {
                    let endpoint = MEndpoint(ref: message.child, type: type)
                    notifyBlock(.endpointRemoved(endpoint))
                }
                
            default:
                notifyBlock(.other)
            }
        })
        guard result == noErr else {
            throw Error.osStatus(result)
        }
        
        self.ref = clientRef
    }
    
    public func createInputPort(name: String, readBlock: @escaping (Packet.List, MEndpoint) -> Void) throws -> MInputPort {
        var portRef = MIDIPortRef()
        let result = MIDIInputPortCreateWithBlock(ref, name as CFString, &portRef, { pktlist, srcConnRefCon in
            guard let srcConnRefCon = srcConnRefCon else { return }
            let endpoint = Unmanaged<MEndpoint>.fromOpaque(srcConnRefCon).takeUnretainedValue()
            
            let list = pktlist.unsafeSequence().map { packetPtr -> Packet in
                let data = Array(packetPtr.bytes())
                return Packet(data: data, timeStamp: TimeStamp(packetPtr.pointee.timeStamp))
            }
            
            readBlock(list, endpoint)
        })
        guard result == noErr else {
            throw Error.osStatus(result)
        }
        
        return MInputPort(ref: portRef)
    }
    
    public func createOutputPort(name: String) throws -> MOutputPort {
        var portRef = MIDIPortRef()
        let result = MIDIOutputPortCreate(ref, name as CFString, &portRef)
        guard result == noErr else {
            throw Error.osStatus(result)
        }
        
        return MOutputPort(ref: portRef)
    }
}

public class MPort {
    public typealias Ref = MIDIPortRef
    
    public let ref: Ref
    
    init(ref: Ref) {
        self.ref = ref
    }
}

public class MInputPort: MPort {
    public func connect(source: MEndpoint) throws {
        guard source.type == .source else { throw Error.invalidType }
        
        let result = MIDIPortConnectSource(ref, source.ref, Unmanaged.passUnretained(source).toOpaque())
        guard result == noErr else {
            throw Error.osStatus(result)
        }
    }
    
    public func disconnect(source: MEndpoint) throws {
        guard source.type == .source else { throw Error.invalidType }
        
        let result = MIDIPortDisconnectSource(ref, source.ref)
        guard result == noErr else {
            throw Error.osStatus(result)
        }
    }
}

public class MOutputPort: MPort {
    
    public func send(packet: Packet, to destination: MEndpoint) throws {
        guard destination.type == .destination else { throw Error.invalidType }
        
        let packet = packet.coreMidiPacket
        var packetList = MIDIPacketList(numPackets: 1, packet: packet)
        
        let result = MIDISend(ref, destination.ref, &packetList)
        guard result == noErr else {
            throw Error.osStatus(result)
        }
    }
    
    public func flush(destination: MEndpoint) throws {
        guard destination.type == .destination else { throw Error.invalidType }
        
        let result = MIDIFlushOutput(destination.ref)
        guard result == noErr else {
            throw Error.osStatus(result)
        }
    }
}

public enum MEndpointType {
    case source
    case destination
    
    init?(objectType: MIDIObjectType) {
        switch objectType {
        case .source:
            self = .source
        case .destination:
            self = .destination
        default:
            return nil
        }
    }
}

public class MEndpoint {
    public typealias Ref = MIDIEndpointRef
    
    public let ref: Ref
    public let type: MEndpointType
    
    public var uniqueID: UniqueID? {
        var value: UniqueID = 0
        guard MIDIObjectGetIntegerProperty(ref, kMIDIPropertyUniqueID, &value) == noErr else { return nil }
        return value
    }
    
    public var name: String? {
        var value: Unmanaged<CFString>?
        guard MIDIObjectGetStringProperty(ref, kMIDIPropertyName, &value) == noErr else { return nil }
        return value?.takeRetainedValue() as String?
    }
    
    public var manufacturer: String? {
        var value: Unmanaged<CFString>?
        guard MIDIObjectGetStringProperty(ref, kMIDIPropertyManufacturer, &value) == noErr else { return nil }
        return value?.takeRetainedValue() as String?
    }
    
    init(ref: Ref, type: MEndpointType) {
        self.ref = ref
        self.type = type
    }
    
    public static func getSources() -> [MEndpoint] {
        let numberOfSources = MIDIGetNumberOfSources()
        var sources = [MEndpoint]()
        for i in 0 ..< numberOfSources {
            sources.append(MEndpoint(ref: MIDIGetSource(i), type: .source))
        }
        return sources
    }
    
    public static func getDestinations() -> [MEndpoint] {
        let numberOfDestinationas = MIDIGetNumberOfDestinations()
        var destinations = [MEndpoint]()
        for i in 0 ..< numberOfDestinationas {
            destinations.append(MEndpoint(ref: MIDIGetDestination(i), type: .destination))
        }
        return destinations
    }
}

public struct Packet {
    public typealias List = Array<Packet>
    
    public let data: [UInt8]
    public let timeStamp: TimeStamp?
    
    public init(data: [UInt8], timeStamp: TimeStamp? = nil) {
        self.data = data
        self.timeStamp = timeStamp
    }
    
    public var coreMidiPacket: MIDIPacket {
        let builder = MIDIPacket.Builder(maximumNumberMIDIBytes: data.count)
        
        for byte in data {
            builder.append(byte)
        }
        
        return builder.withUnsafePointer { pointer -> MIDIPacket in
            var packet = pointer.pointee
            packet.timeStamp = timeStamp?.coreMidiTimeStamp ?? 0
            return packet
        }
    }
}

public struct TimeStamp {
    
    private static let timebase: mach_timebase_info = {
        var timebase = mach_timebase_info()
        mach_timebase_info(&timebase)
        return timebase
    }()
    
    public static var now: TimeStamp {
        TimeStamp(mach_absolute_time())
    }
    
    public var milliSeconds: Double {
        Double(coreMidiTimeStamp) * Double(Self.timebase.numer) / Double(Self.timebase.denom) / 1_000_000
    }
    
    public let coreMidiTimeStamp: MIDITimeStamp
    
    public init() {
        self.coreMidiTimeStamp = 0
    }
    
    public init(_ coreMidiTimeStamp: MIDITimeStamp) {
        self.coreMidiTimeStamp = coreMidiTimeStamp
    }
    
    public init(_ milliSeconds: Double) {
        let value = milliSeconds * 1_000_000 * Double(Self.timebase.denom) / Double(Self.timebase.numer)
        if Double(MIDITimeStamp.min)...Double(MIDITimeStamp.max) ~= value {
            self.coreMidiTimeStamp = MIDITimeStamp(value)
        } else {
            self.coreMidiTimeStamp = MIDITimeStamp(0)
        }
    }
}

public func +(left: TimeStamp, right: TimeStamp) -> TimeStamp {
    let value = left.coreMidiTimeStamp &+ right.coreMidiTimeStamp
    guard value >= left.coreMidiTimeStamp else {
        return TimeStamp()
    }
    return TimeStamp(value)
}

public func -(left: TimeStamp, right: TimeStamp) -> TimeStamp {
    let value = left.coreMidiTimeStamp &- right.coreMidiTimeStamp
    guard value <= left.coreMidiTimeStamp else {
        return TimeStamp()
    }
    return TimeStamp(value)
}
