import Foundation
import Combine

/// Modèle de vue exposé au panneau SwiftUI. Purement des données, aucune logique AppKit.

/// État d'un arrêt dans la desserte du train.
enum StopStatus {
    case passed    // Arrêt déjà desservi
    case current   // Prochain arrêt / arrêt en cours
    case upcoming  // Arrêt à venir
}

/// Un arrêt affiché dans la timeline.
struct StopRow: Identifiable {
    let id: String
    let label: String
    /// Heure théorique "HH:mm" (affichée barrée si retard).
    let theoricTime: String
    /// Heure réelle "HH:mm".
    let realTime: String
    let delayMin: Int
    let status: StopStatus
}

/// Une gare proposée dans le sélecteur "Gare d'arrivée".
struct ArrivalOption: Identifiable {
    let id: String
    let label: String
}

/// Instantané de tout ce que le panneau affiche pour un train connecté.
struct TrainViewState {
    var trainNumber: String?
    var destination: String?
    var delayMin: Int
    var delayCause: String

    var stops: [StopRow]
    var globalProgress: Double

    var speedKmh: Int

    var wifiQuality: Int?      // 0…5
    var wifiDevices: Int?

    // Data en Mo
    var dataConsumedMB: Double?
    var dataTotalMB: Double?
    var dataRemainingMB: Double?
    var dataRatio: Double?     // 0…1
    var dataResetTime: String? // "HH:mm"

    var arrivalOptions: [ArrivalOption]
    var selectedArrivalId: String?
}

/// État global du panneau.
enum PanelState {
    case loading
    case notConnected(demoMode: Bool)
    case connected(TrainViewState)
}

/// Source d'observation pour la vue SwiftUI. Le `MenuBarController` pousse l'état
/// et branche les closures d'action (elles appellent les `@objc` existants).
final class TrainStore: ObservableObject {
    @Published var state: PanelState = .loading

    /// Date de la dernière actualisation réussie (pour l'indicateur discret du panneau).
    @Published var lastRefreshDate: Date?
    /// Intervalle entre deux actualisations automatiques (doit refléter le Timer du contrôleur).
    let refreshInterval: TimeInterval = 30

    // Actions branchées par le contrôleur AppKit.
    var onRefresh: () -> Void = {}
    var onQuit: () -> Void = {}
    var onSelectArrival: (String) -> Void = { _ in }
    var onToggleDemo: () -> Void = {}
    var onOpenDemoPanel: () -> Void = {}
    var onCopyJSON: () -> Void = {}
    var onOpenAbout: () -> Void = {}
    /// Appelée quand un réglage de notification change (pour relancer un refresh).
    var onSettingsChanged: () -> Void = {}
}
