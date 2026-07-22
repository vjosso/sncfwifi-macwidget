import SwiftUI
import Combine

/// Largeur fixe du panneau (style Centre de contrôle).
private let panelWidth: CGFloat = 300

extension Color {
    /// Carmillon — couleur de marque SNCF / TGV INOUI (#7D206F).
    static let carmillon = Color(red: 125.0 / 255.0, green: 32.0 / 255.0, blue: 111.0 / 255.0)
}

// MARK: - Vue racine

struct TrainPanelView: View {
    @EnvironmentObject var store: TrainStore

    var body: some View {
        VStack(spacing: 0) {
            switch store.state {
            case .loading:
                LoadingView()
            case .notConnected(let demoMode):
                NotConnectedView(demoMode: demoMode)
            case .connected(let state):
                ConnectedView(state: state)
            }
            Divider()
            FooterView()
        }
        .frame(width: panelWidth)
    }
}

// MARK: - États simples

private struct LoadingView: View {
    var body: some View {
        VStack(spacing: 10) {
            ProgressView()
            Text("Chargement…")
                .font(.callout)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

private struct NotConnectedView: View {
    @EnvironmentObject var store: TrainStore
    let demoMode: Bool

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: demoMode ? "network.slash" : "wifi.slash")
                .font(.system(size: 34, weight: .light))
                .foregroundColor(.secondary)

            if demoMode {
                Text("Serveur démo indisponible")
                    .font(.headline)
                Text("Démarre-le avec ./start_demo_server.sh")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Button("Ouvrir le panneau démo") { store.onOpenDemoPanel() }
            } else {
                Text("Non connecté au WiFi SNCF inOui")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                Text("(ou API du train indisponible)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 28)
    }
}

// MARK: - Contenu train connecté

private struct ConnectedView: View {
    let state: TrainViewState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HeaderView(state: state)

                if !state.stops.isEmpty {
                    Divider()
                    TimelineView(stops: state.stops)
                }

                if state.wifiQuality != nil || state.dataRatio != nil {
                    Divider()
                    if let quality = state.wifiQuality {
                        WifiView(quality: quality, devices: state.wifiDevices)
                    }
                    if let ratio = state.dataRatio {
                        DataView(state: state, ratio: ratio)
                    }
                }

                RefreshStatusView()
                    .padding(.top, 2)
            }
            .padding(16)
        }
        .frame(maxHeight: 460)
    }
}

// MARK: - En-tête

private struct HeaderView: View {
    let state: TrainViewState

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "tram.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.carmillon)
                VStack(alignment: .leading, spacing: 1) {
                    Text(state.trainNumber.map { "TGV INOUI n° \($0)" } ?? "TGV INOUI")
                        .font(.system(size: 14, weight: .semibold))
                    if let dest = state.destination, !dest.isEmpty {
                        Text("→ \(dest)")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                Spacer(minLength: 8)
                if state.speedKmh > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "speedometer")
                            .foregroundColor(.carmillon)
                        Text("\(state.speedKmh) km/h")
                            .foregroundColor(.primary)
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .fixedSize()
                }
            }

            if state.delayMin > 0 {
                HStack(spacing: 5) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(delayText)
                        .foregroundColor(.orange)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .font(.system(size: 11, weight: .medium))
            }
        }
    }

    private var delayText: String {
        var t = "Retard +\(state.delayMin) min"
        if !state.delayCause.isEmpty { t += " · \(state.delayCause)" }
        return t
    }
}

// MARK: - Timeline des arrêts

private struct TimelineView: View {
    let stops: [StopRow]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(stops.enumerated()), id: \.element.id) { index, stop in
                StopRowView(stop: stop,
                            isFirst: index == 0,
                            isLast: index == stops.count - 1)
            }
        }
    }
}

private struct StopRowView: View {
    let stop: StopRow
    let isFirst: Bool
    let isLast: Bool

    private var dotColor: Color {
        switch stop.status {
        case .passed:   return .carmillon
        case .current:  return .carmillon
        case .upcoming: return .secondary
        }
    }

    private var symbol: String {
        switch stop.status {
        case .passed:   return "checkmark.circle.fill"
        case .current:  return "record.circle.fill"
        case .upcoming: return "circle"
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Colonne rail + pastille
            ZStack(alignment: .top) {
                Rectangle()
                    .fill(Color.secondary.opacity(0.35))
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
                    .padding(.top, isFirst ? 9 : 0)
                    .padding(.bottom, isLast ? 9 : 0)
                Image(systemName: symbol)
                    .font(.system(size: 15))
                    .foregroundColor(dotColor)
            }
            .frame(width: 18)

            // Libellé + horaires
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(stop.label)
                    .font(.system(size: 12, weight: stop.status == .current ? .semibold : .regular))
                    .foregroundColor(stop.status == .upcoming ? .secondary : .primary)
                Spacer(minLength: 4)
                if stop.delayMin > 0 && !stop.theoricTime.isEmpty && stop.theoricTime != stop.realTime {
                    Text(stop.theoricTime)
                        .strikethrough()
                        .foregroundColor(.secondary)
                    Text(stop.realTime)
                        .foregroundColor(.orange)
                } else if !stop.realTime.isEmpty {
                    Text(stop.realTime)
                        .foregroundColor(.secondary)
                }
            }
            .font(.system(size: 12))
            .padding(.bottom, isLast ? 0 : 12)
        }
    }
}

// MARK: - Qualité WiFi

private struct WifiView: View {
    let quality: Int
    let devices: Int?

    var body: some View {
        HStack(spacing: 16) {
            MetricPill(symbol: quality >= 3 ? "wifi" : "wifi.exclamationmark",
                       text: wifiText,
                       tint: quality < 3 ? .orange : .carmillon)
            Spacer(minLength: 0)
        }
    }

    private var wifiText: String {
        var t = "WiFi \(quality)/5"
        if let d = devices { t += " · \(d) pers." }
        return t
    }
}

private struct MetricPill: View {
    let symbol: String
    let text: String
    var tint: Color = .carmillon

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: symbol).foregroundColor(tint)
            Text(text).foregroundColor(.primary)
        }
        .font(.system(size: 12, weight: .medium))
    }
}

// MARK: - Consommation data

private struct DataView: View {
    let state: TrainViewState
    let ratio: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label("Données", systemImage: "arrow.up.arrow.down.circle")
                    .font(.system(size: 12, weight: .medium))
                Spacer()
                Text("\(Int((ratio * 100).rounded())) %")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            ProgressView(value: min(max(ratio, 0), 1))
                .accentColor(ratio > 0.85 ? .red : .carmillon)
            if let consumed = state.dataConsumedMB, let total = state.dataTotalMB {
                Text(usageLine(consumed: consumed, total: total, reset: state.dataResetTime))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
    }

    private func usageLine(consumed: Double, total: Double, reset: String?) -> String {
        var t = String(format: "%.1f / %.1f Mo utilisés", consumed, total)
        if let reset = reset { t += " · reset \(reset)" }
        return t
    }
}

// MARK: - Indicateur discret d'actualisation

private struct RefreshStatusView: View {
    @EnvironmentObject var store: TrainStore
    @State private var now = Date()
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        f.timeZone = .current
        return f
    }()

    var body: some View {
        HStack {
            Spacer()
            if let text = statusText {
                Text(text)
                    .font(.system(size: 10))
                    .foregroundColor(Color.secondary.opacity(0.7))
            }
            Spacer()
        }
        .onReceive(ticker) { now = $0 }
    }

    private var statusText: String? {
        guard let last = store.lastRefreshDate else { return nil }
        let elapsed = now.timeIntervalSince(last)
        let remaining = max(0, Int((store.refreshInterval - elapsed).rounded()))
        return "Actualisé à \(RefreshStatusView.timeFormatter.string(from: last)) · prochaine dans \(remaining) s"
    }
}

// MARK: - Pied de page (actions + réglages + debug)

private struct FooterView: View {
    @EnvironmentObject var store: TrainStore

    @AppStorage("notifyBeforeArrivalEnabled") private var notifyEnabled = true
    @AppStorage("notifyBeforeArrivalMinutes") private var notifyMinutes = 10
    @AppStorage("notifyBeforeArrivalTarget") private var notifyTarget = "selectedArrival"
    @AppStorage("isDemoMode") private var demoMode = false

    private let leadTimes = [5, 10, 15]

    var body: some View {
        HStack(spacing: 4) {
            footerButton("arrow.2.circlepath", help: "Actualiser") { store.onRefresh() }

            settingsMenu
            debugMenu

            Spacer()

            footerButton("info.circle", help: "À propos") { store.onOpenAbout() }
            footerButton("power", help: "Quitter") { store.onQuit() }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    /// Options de gare d'arrivée, disponibles uniquement quand un train est connecté.
    private var arrival: (options: [ArrivalOption], selectedId: String?)? {
        if case let .connected(state) = store.state, !state.arrivalOptions.isEmpty {
            return (state.arrivalOptions, state.selectedArrivalId)
        }
        return nil
    }

    private var settingsMenu: some View {
        Menu {
            if let arrival = arrival {
                Menu("Gare d'arrivée") {
                    ForEach(arrival.options) { option in
                        Button {
                            store.onSelectArrival(option.id)
                        } label: {
                            checkLabel(option.label, on: option.id == arrival.selectedId)
                        }
                    }
                }
                Divider()
            }

            Button {
                notifyEnabled.toggle()
                store.onSettingsChanged()
            } label: {
                checkLabel("Notification avant arrivée", on: notifyEnabled)
            }

            Menu("Délai de notification") {
                ForEach(leadTimes, id: \.self) { minutes in
                    Button {
                        notifyMinutes = minutes
                        store.onSettingsChanged()
                    } label: {
                        checkLabel("\(minutes) min", on: notifyMinutes == minutes)
                    }
                }
            }

            Menu("Type de notification") {
                Button {
                    notifyTarget = "selectedArrival"
                    store.onSettingsChanged()
                } label: {
                    checkLabel("Gare d'arrivée sélectionnée", on: notifyTarget == "selectedArrival")
                }
                Button {
                    notifyTarget = "nextStop"
                    store.onSettingsChanged()
                } label: {
                    checkLabel("Prochaine gare", on: notifyTarget == "nextStop")
                }
            }
        } label: {
            Image(systemName: "gearshape.fill")
        }
        .menuStyle(BorderlessButtonMenuStyle())
        .fixedSize()
        .help("Réglages")
    }

    private var debugMenu: some View {
        Menu {
            Button {
                store.onToggleDemo()
            } label: {
                checkLabel("Mode Démo (serveur local)", on: demoMode)
            }
            Button("Ouvrir le panneau démo") { store.onOpenDemoPanel() }
            Divider()
            Button {
                store.onCopyJSON()
            } label: {
                Label("Copier le JSON", systemImage: "doc.on.doc")
            }
        } label: {
            Image(systemName: "ladybug.fill")
        }
        .menuStyle(BorderlessButtonMenuStyle())
        .fixedSize()
        .help("Debug")
    }

    @ViewBuilder
    private func checkLabel(_ title: String, on: Bool) -> some View {
        if on {
            Label(title, systemImage: "checkmark")
        } else {
            Text(title)
        }
    }

    private func footerButton(_ symbol: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 14))
                .frame(width: 26, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .help(help)
    }
}
