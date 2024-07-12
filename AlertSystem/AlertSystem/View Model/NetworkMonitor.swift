import Foundation
import Network
import Combine

class NetworkMonitor: ObservableObject {
    private var monitor: NWPathMonitor
    private var queue = DispatchQueue(label: "NetworkMonitorQueue")
    
    @Published var isConnected: Bool = false
    private var statusChangePublisher = PassthroughSubject<Bool, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.monitor = NWPathMonitor()
        startMonitoring()
        
        statusChangePublisher
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] newStatus in
                print("Network status updated: \(newStatus ? "Connected" : "Disconnected")")
                self?.isConnected = newStatus
            }
            .store(in: &cancellables)
    }
    
    deinit {
        stopMonitoring()
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            DispatchQueue.main.async {
                let newStatus = path.status == .satisfied
                print("Path update handler called: \(newStatus ? "Connected" : "Disconnected")")
                self.statusChangePublisher.send(newStatus)
            }
        }
        monitor.start(queue: queue)
    }
    
    private func stopMonitoring() {
        monitor.cancel()
    }
}
