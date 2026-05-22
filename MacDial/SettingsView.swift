
import SwiftUI
import AppKit

// MARK: - Root

struct SettingsView: View {
    @ObservedObject var settings: DialSettings
    @State private var selection: SettingsSection = .scroll

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            List(SettingsSection.allCases, selection: $selection) { section in
                Label(section.title, systemImage: section.icon).tag(section)
            }
            .navigationSplitViewColumnWidth(min: 160, ideal: 180, max: 200)
        } detail: {
            detailView
        }
        .navigationSplitViewStyle(.balanced)
        .modifier(HideSidebarToggle())
        .frame(width: 740, height: 520)
    }

    @ViewBuilder
    private var detailView: some View {
        switch selection {
        case .scroll:   ScrollSettingsDetail(settings: settings)
        case .playback: PlaybackSettingsDetail(settings: settings)
        case .fcp:      FCPSettingsDetail(settings: settings)
        case .zoom:     ZoomSettingsDetail(settings: settings)
        case .meetings: MeetingsSettingsDetail(settings: settings)
        case .phone:    PhoneSettingsDetail(settings: settings)
        }
    }
}

// MARK: - Sections

enum SettingsSection: String, CaseIterable, Identifiable {
    case scroll, playback, fcp, zoom, meetings, phone
    var id: String { rawValue }
    var title: String {
        switch self {
        case .scroll:   return "Scrolling"
        case .playback: return "Playing"
        case .fcp:      return "Scrubbing"
        case .zoom:     return "Zooming"
        case .meetings: return "Conferencing"
        case .phone:    return "Calling"
        }
    }
    var icon: String {
        switch self {
        case .scroll:   return "arrow.up.arrow.down"
        case .playback: return "playpause"
        case .fcp:      return "forward.frame"
        case .zoom:     return "magnifyingglass"
        case .meetings: return "video.fill"
        case .phone:    return "phone.fill"
        }
    }
}

// MARK: - Scroll

struct ScrollSettingsDetail: View {
    @ObservedObject var settings: DialSettings
    var body: some View {
        Form {
            Section {
                Picker("Direction", selection: $settings.scrollDirection) {
                    ForEach(DialSettings.DirectionOption.allCases) { Text($0.label).tag($0) }
                }
                Picker("Sensitivity", selection: $settings.scrollSensitivity) {
                    ForEach(DialSettings.SensitivityOption.allCases) { Text($0.label).tag($0) }
                }
                Toggle("Haptic feedback", isOn: $settings.scrollHaptics)
            }
            Section("Button Press") {
                Picker("Single press", selection: $settings.scrollSinglePress) {
                    ForEach(PressAction.scrollOptions) { Text($0.label).tag($0) }
                }
                Picker("Double press", selection: $settings.scrollDoublePress) {
                    ForEach(PressAction.scrollOptions) { Text($0.label).tag($0) }
                }
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Playback

struct PlaybackSettingsDetail: View {
    @ObservedObject var settings: DialSettings
    var body: some View {
        Form {
            Section {
                SensitivityRow(value: $settings.playbackSensitivity)
                Toggle("Haptic feedback", isOn: $settings.playbackHaptics)
            }
            Section("Button Press") {
                Picker("Single press", selection: $settings.playbackSinglePress) {
                    ForEach(PressAction.playbackOptions) { Text($0.label).tag($0) }
                }
                Picker("Double press", selection: $settings.playbackDoublePress) {
                    ForEach(PressAction.playbackOptions) { Text($0.label).tag($0) }
                }
            }
            Section("Rotation") {
                InfoRow("Clockwise",         detail: "Volume up")
                InfoRow("Counter-clockwise", detail: "Volume down")
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - FCP Scrub

struct FCPSettingsDetail: View {
    @ObservedObject var settings: DialSettings
    var body: some View {
        Form {
            Section {
                Picker("Sensitivity", selection: $settings.fcpSensitivity) {
                    ForEach(DialSettings.SensitivityOption.allCases) { Text($0.label).tag($0) }
                }
                Toggle("Haptic feedback", isOn: $settings.fcpHaptics)
            }
            Section("Button Press") {
                Picker("Single press", selection: $settings.fcpSinglePress) {
                    ForEach(PressAction.fcpOptions) { Text($0.label).tag($0) }
                }
                Picker("Double press", selection: $settings.fcpDoublePress) {
                    ForEach(PressAction.fcpOptions) { Text($0.label).tag($0) }
                }
            }
            Section("Rotation") {
                InfoRow("Slow", detail: "1 frame  ←/→")
                InfoRow("Fast", detail: "10 frames  Shift+←/→")
            }
            autoSwitchSection(
                caption: "Switch to FCP Scrub when these apps become active.",
                bundleIds: $settings.autoSwitchBundleIds
            )
        }
        .formStyle(.grouped)
    }
}

// MARK: - Zoom

struct ZoomSettingsDetail: View {
    @ObservedObject var settings: DialSettings
    var body: some View {
        Form {
            Section {
                Picker("Sensitivity", selection: $settings.zoomSensitivity) {
                    ForEach(DialSettings.SensitivityOption.allCases) { Text($0.label).tag($0) }
                }
                Toggle("Haptic feedback", isOn: $settings.zoomHaptics)
            }
            Section("Button Press") {
                Picker("Single press", selection: $settings.zoomSinglePress) {
                    ForEach(PressAction.zoomOptions) { Text($0.label).tag($0) }
                }
                Picker("Double press", selection: $settings.zoomDoublePress) {
                    ForEach(PressAction.zoomOptions) { Text($0.label).tag($0) }
                }
            }
            Section("Rotation") {
                InfoRow("Clockwise",         detail: "Zoom in  (⌘=)")
                InfoRow("Counter-clockwise", detail: "Zoom out  (⌘–)")
            }
            autoSwitchSection(
                caption: "Switch to Zooming when these apps become active.",
                bundleIds: $settings.zoomAutoSwitchBundleIds
            )
        }
        .formStyle(.grouped)
    }
}

// MARK: - Meetings

struct MeetingsSettingsDetail: View {
    @ObservedObject var settings: DialSettings
    var body: some View {
        Form {
            Section {
                SensitivityRow(value: $settings.meetingsSensitivity)
                Toggle("Haptic feedback", isOn: $settings.meetingsHaptics)
            }
            Section("Button Press") {
                Picker("Single press", selection: $settings.meetingsSinglePress) {
                    ForEach(PressAction.meetingOptions) { Text($0.label).tag($0) }
                }
                Picker("Double press", selection: $settings.meetingsDoublePress) {
                    ForEach(PressAction.meetingOptions) { Text($0.label).tag($0) }
                }
            }
            autoSwitchSection(
                caption: "Switch to Meetings when these apps become active.",
                bundleIds: $settings.meetingsAutoSwitchBundleIds
            )
        }
        .formStyle(.grouped)
    }
}

// MARK: - Phone

struct PhoneSettingsDetail: View {
    @ObservedObject var settings: DialSettings
    var body: some View {
        Form {
            Section {
                SensitivityRow(value: $settings.phoneSensitivity)
                Toggle("Haptic feedback", isOn: $settings.phoneHaptics)
            }
            Section("Button Press") {
                Picker("Single press", selection: $settings.phoneSinglePress) {
                    ForEach(PressAction.phoneOptions) { Text($0.label).tag($0) }
                }
                Picker("Double press", selection: $settings.phoneDoublePress) {
                    ForEach(PressAction.phoneOptions) { Text($0.label).tag($0) }
                }
            }
            autoSwitchSection(
                caption: "Switch to Phone mode when these apps become active.",
                bundleIds: $settings.phoneAutoSwitchBundleIds
            )
        }
        .formStyle(.grouped)
    }
}

// MARK: - Shared

@ViewBuilder
private func autoSwitchSection(caption: String, bundleIds: Binding<[String]>) -> some View {
    Section("Auto-Switch") {
        VStack(alignment: .leading, spacing: 10) {
            Text(caption)
                .foregroundColor(.secondary)
                .font(.callout)
            AppListEditor(bundleIds: bundleIds)
        }
        .padding(.vertical, 4)
    }
}

private struct SensitivityRow: View {
    @Binding var value: Double

    private let logMin = log10(10.0)
    private let logMax = log10(400.0)

    private var sliderBinding: Binding<Double> {
        Binding(
            get: { (log10(max(10.0, min(400.0, value))) - logMin) / (logMax - logMin) },
            set: { value = pow(10, $0 * (logMax - logMin) + logMin) }
        )
    }

    private var displayString: String {
        String(format: "%.0f steps/rev", value)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Sensitivity")
                Spacer()
                Text(displayString)
                    .foregroundColor(.secondary)
                    .font(.callout.monospacedDigit())
            }
            Slider(value: sliderBinding, in: 0...1)
        }
        .padding(.vertical, 2)
    }
}

private struct InfoRow: View {
    let label: String; let detail: String
    init(_ label: String, detail: String) { self.label = label; self.detail = detail }
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(detail).foregroundColor(.secondary)
        }
    }
}

// MARK: - App List Editor

private struct AppListEditor: View {
    @Binding var bundleIds: [String]
    @State private var selection: String? = nil

    var body: some View {
        VStack(spacing: 0) {
            List(selection: $selection) {
                ForEach(bundleIds, id: \.self) { id in
                    AppRow(bundleId: id).tag(id)
                }
            }
            .listStyle(.inset)
            .frame(height: max(72, CGFloat(bundleIds.count) * 26 + 2).clamped(to: 72...150))

            Divider()

            HStack(spacing: 0) {
                Button { addApp() } label: {
                    Image(systemName: "plus").frame(width: 28, height: 22)
                }
                .buttonStyle(.borderless)

                Rectangle()
                    .fill(Color(NSColor.separatorColor))
                    .frame(width: 1, height: 14)

                Button {
                    if let id = selection { bundleIds.removeAll { $0 == id }; selection = nil }
                } label: {
                    Image(systemName: "minus").frame(width: 28, height: 22)
                }
                .buttonStyle(.borderless)
                .disabled(selection == nil || bundleIds.isEmpty)

                Spacer()
            }
            .background(Color(NSColor.controlBackgroundColor))
        }
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(NSColor.separatorColor), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func addApp() {
        let panel = NSOpenPanel()
        panel.allowedFileTypes = ["app"]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.title = "Choose Application"; panel.prompt = "Add"
        guard panel.runModal() == .OK, let url = panel.url,
              let bid = Bundle(url: url)?.bundleIdentifier,
              !bundleIds.contains(bid) else { return }
        bundleIds.append(bid)
    }
}

private struct AppRow: View {
    let bundleId: String
    var body: some View {
        let url  = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId)
        let name: String = {
            guard let url else { return bundleId }
            let b = Bundle(url: url)
            return (b?.localizedInfoDictionary?["CFBundleDisplayName"] as? String)
                ?? (b?.infoDictionary?["CFBundleDisplayName"] as? String)
                ?? (b?.infoDictionary?["CFBundleName"] as? String)
                ?? url.deletingPathExtension().lastPathComponent
        }()
        HStack(spacing: 8) {
            if let url {
                Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                    .resizable().interpolation(.high).frame(width: 18, height: 18)
            }
            Text(name).lineLimit(1)
        }
    }
}

private struct HideSidebarToggle: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 14, *) {
            content.toolbar(removing: .sidebarToggle)
        } else {
            content
        }
    }
}

// MARK: - Helpers

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        if self < range.lowerBound { return range.lowerBound }
        if self > range.upperBound { return range.upperBound }
        return self
    }
}
