import SwiftUI
import UserNotifications
import Combine

struct PendingRemedy: Identifiable, Equatable {
    let id = UUID()
    let remedyName: String
    let ailment: String
}

struct ProfileView: View {
    @StateObject private var viewModel: ProfileViewModel
    let appState: AppState
    @StateObject private var remedyProgressVM = RemedyProgressViewModel()
    @State private var showLogSheet: RemedyProgress? = nil
    @State private var showReminderSheet: RemedyProgress? = nil
    @State private var showCheckInSheet: RemedyProgress? = nil
    @State private var pendingRemedy: PendingRemedy? = nil
    @State private var reminderRemedyName: String = ""
    @State private var reminderAilment: String = ""
    
    init(appState: AppState) {
        self.appState = appState
        _viewModel = StateObject(wrappedValue: ProfileViewModel(appState: appState))
    }
    
    var body: some View {
        profileContent
    }
    
    private var profileContent: some View {
        NavigationView {
            List {
                primaryProfileSection
                familyProfilesSection
                settingsSection
                remedyProgressSection
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $viewModel.showingProfileSheet) {
                ProfileFormView(
                    isPrimary: viewModel.primaryProfile == nil,
                    onSave: viewModel.saveProfile
                )
            }
            .sheet(item: $showCheckInSheet) { remedy in
                CheckInSheet(remedy: remedy, viewModel: remedyProgressVM)
            }
            .sheet(item: $pendingRemedy, onDismiss: { pendingRemedy = nil }) { pending in
                InitialSeveritySheet(remedyName: pending.remedyName, ailment: pending.ailment, viewModel: remedyProgressVM) { entry in
                    showCheckInSheet = entry
                }
            }
            .sheet(item: $showLogSheet) { remedy in
                RemedyLogSheet(remedy: remedy, viewModel: remedyProgressVM)
            }
            .sheet(item: $showReminderSheet) { remedy in
                RemedyReminderSheet(remedy: remedy, viewModel: remedyProgressVM)
            }
            .onReceive(NotificationCenter.default.publisher(for: .startTrackingRemedy)) { notification in
                if let remedyName = notification.userInfo?["remedyName"] as? String,
                   let ailment = notification.userInfo?["ailment"] as? String {
                    pendingRemedy = PendingRemedy(remedyName: remedyName, ailment: ailment)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .setRemindersForRemedy)) { notification in
                if let remedyName = notification.userInfo?["remedyName"] as? String,
                   let ailment = notification.userInfo?["ailment"] as? String {
                    reminderRemedyName = remedyName
                    reminderAilment = ailment
                    showReminderSheet = RemedyProgress(remedyName: remedyName, ailment: ailment)
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.error?.localizedDescription ?? "An unknown error occurred")
            }
            .background(AppTheme.colors.background)
        }
    }
    
    private var primaryProfileSection: some View {
                Section("Primary Profile") {
                    if let primaryProfile = viewModel.primaryProfile {
                        ProfileRow(profile: primaryProfile)
                    } else {
                        Button(action: viewModel.showAddProfile) {
                            Label("Add Primary Profile", systemImage: "person.badge.plus")
                                .foregroundColor(AppTheme.colors.sageGreen)
                }
                        }
                    }
                }
                
    private var familyProfilesSection: some View {
                Section("Family Profiles") {
                    ForEach(viewModel.familyProfiles) { profile in
                        ProfileRow(profile: profile)
                    }
                    Button(action: viewModel.showAddProfile) {
                        Label("Add Family Member", systemImage: "person.badge.plus")
                            .foregroundColor(AppTheme.colors.sageGreen)
            }
                    }
                }
                
    private var settingsSection: some View {
                Section("Settings") {
                    NavigationLink {
                        NotificationSettingsView()
                    } label: {
                        Label("Notifications", systemImage: "bell.fill")
                            .foregroundColor(AppTheme.colors.text)
                    }
                    NavigationLink {
                        PrivacySettingsView()
                    } label: {
                        Label("Privacy", systemImage: "lock.fill")
                            .foregroundColor(AppTheme.colors.text)
                    }
                    NavigationLink {
                        LegalView()
                    } label: {
                        Label("Legal", systemImage: "doc.text.fill")
                            .foregroundColor(AppTheme.colors.text)
                    }
                    Button(action: viewModel.signOut) {
                        Label("Sign Out", systemImage: "arrow.right.square.fill")
                            .foregroundColor(AppTheme.colors.error)
                    }
                }
            }
    
    private var remedyProgressSection: some View {
        Section("Remedy Progress") {
            if remedyProgressVM.activeRemedies.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "leaf.circle")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.secondary)
                    Text("No remedies being tracked yet.")
                        .foregroundColor(.secondary)
                        .padding()
                }
                .frame(maxWidth: .infinity)
            } else {
                ForEach(remedyProgressVM.activeRemedies.filter { $0.isActive }) { remedy in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 12) {
                            Image(systemName: "leaf.fill")
                                .resizable()
                                .frame(width: 32, height: 32)
                                .foregroundColor(.green)
                                .shadow(radius: 2)
                            VStack(alignment: .leading) {
                                Text(remedy.remedyName)
                                    .font(.headline)
                                Text("Started: \(remedy.startDate, formatter: dateFormatter)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        if let lastLog = remedy.dailyLogs.last {
                            Text("Last log: \(lastLog.date, formatter: dateFormatter)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        if !remedy.dailyLogs.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Log History:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                ForEach(remedy.dailyLogs.sorted(by: { $0.date > $1.date })) { log in
                                    HStack {
                                        Text(log.date, formatter: dateFormatter)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        if let severity = log.symptomSeverity {
                                            Text("Severity: \(severity)")
                                                .font(.caption2)
                                                .foregroundColor(severity <= 3 ? .green : severity <= 6 ? .orange : .red)
                                        }
                                        Text(log.note)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        HStack {
                            Button("Log Progress") { showLogSheet = remedy }
                                .buttonStyle(.borderedProminent)
                            Button("Set Reminder") { showReminderSheet = remedy }
                                .buttonStyle(.bordered)
                            Button("Complete") { remedyProgressVM.completeRemedy(remedy.id) }
                                .buttonStyle(.bordered)
            }
                    }
                    .padding(.vertical, 12)
                    .background(Color(.systemBackground).opacity(0.7))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
                    .padding(.vertical, 4)
                }
            }
        }
    }
}

struct ProfileRow: View {
    let profile: Profile
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(profile.name)
                    .appHeadline()
                
                if !profile.allergies.isEmpty {
                    Text("Allergies: \(profile.allergies.joined(separator: ", "))")
                        .appCaption()
                }
            }
            
            Spacer()
            
            if appState.selectedProfile?.id == profile.id {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(AppTheme.colors.success)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            appState.selectedProfile = profile
        }
    }
}

class ProfileViewModel: ObservableObject {
    @Published var primaryProfile: Profile?
    @Published var familyProfiles: [Profile] = []
    @Published var showingProfileSheet = false
    @Published var showError = false
    @Published var error: Error?
    var appState: AppState?
    
    init(appState: AppState?) {
        self.appState = appState
        // Don't call loadProfiles here, wait until appState is set in the view
    }
    
    func loadProfiles() {
        guard let userId = appState?.currentUser?.id else { return }
        
        Task {
            do {
                let profiles = try await FirebaseService.shared.fetchProfiles(for: userId)
                await MainActor.run {
                    self.primaryProfile = profiles.first { $0.isPrimaryProfile }
                    self.familyProfiles = profiles.filter { !$0.isPrimaryProfile }
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    self.showError = true
                }
            }
        }
    }
    
    func showAddProfile() {
        showingProfileSheet = true
    }
    
    func saveProfile(_ profile: Profile) {
        Task {
            do {
                try await FirebaseService.shared.saveProfile(profile)
                CoreDataManager.shared.saveProfile(profile)
                await MainActor.run {
                    loadProfiles()
                    showingProfileSheet = false
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    self.showError = true
                }
            }
        }
    }
    
    func signOut() {
        do {
            try FirebaseService.shared.signOut()
            appState?.isAuthenticated = false
            appState?.currentUser = nil
            appState?.selectedProfile = nil
        } catch {
            self.error = error
            self.showError = true
        }
    }
}

struct NotificationSettingsView: View {
    var body: some View {
        Text("Notification Settings")
            .appTitle()
            .background(AppTheme.colors.background)
    }
}

struct PrivacySettingsView: View {
    var body: some View {
        Text("Privacy Settings")
            .appTitle()
            .background(AppTheme.colors.background)
    }
}

struct LegalView: View {
    var body: some View {
        Text("Legal")
            .appTitle()
            .background(AppTheme.colors.background)
    }
}

struct CheckInSheet: View {
    let remedy: RemedyProgress
    @ObservedObject var viewModel: RemedyProgressViewModel
    @Environment(\.dismiss) var dismiss
    @State private var severity: Int = 5
    @State private var note: String = ""
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("How severe are your symptoms? (1-10)")) {
                    Stepper(value: $severity, in: 1...10) {
                        Text("\(severity)")
                    }
                }
                Section(header: Text("Notes (optional)")) {
                    TextField("Describe your progress...", text: $note)
                }
            }
            .navigationTitle("Log Progress")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.logProgress(for: remedy.id, note: note, severity: severity)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct InitialSeveritySheet: View {
    let remedyName: String
    let ailment: String
    @ObservedObject var viewModel: RemedyProgressViewModel
    var onComplete: (RemedyProgress) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var severity: Int = 5
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("How severe are your symptoms? (1-10)")) {
                    Stepper(value: $severity, in: 1...10) {
                        Text("\(severity)")
                    }
                }
            }
            .navigationTitle("Start Tracking")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") {
                        viewModel.addRemedy(remedyName, ailment: ailment)
                        if let remedy = viewModel.activeRemedies.last {
                            viewModel.logProgress(for: remedy.id, note: "Initial log", severity: severity)
                            onComplete(remedy)
                        }
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct RemedyLogSheet: View {
    let remedy: RemedyProgress
    @ObservedObject var viewModel: RemedyProgressViewModel
    @Environment(\.dismiss) var dismiss
    @State private var severity: Int = 5
    @State private var note: String = ""
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("How severe are your symptoms? (1-10)")) {
                    Stepper(value: $severity, in: 1...10) {
                        Text("\(severity)")
                    }
                }
                Section(header: Text("Notes (optional)")) {
                    TextField("Describe your progress...", text: $note)
                }
            }
            .navigationTitle("Log Progress")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.logProgress(for: remedy.id, note: note, severity: severity)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct RemedyReminderSheet: View {
    let remedy: RemedyProgress
    @ObservedObject var viewModel: RemedyProgressViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Set a daily reminder for \(remedy.remedyName)")) {
                    DatePicker("Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                }
                Section {
                    Button("Schedule Reminder") {
                        let comps = Calendar.current.dateComponents([.hour, .minute], from: selectedTime)
                        viewModel.setReminder(for: remedy.id, time: comps)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle("Set Reminder")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

private let dateFormatter: DateFormatter = {
    let df = DateFormatter()
    df.dateStyle = .medium
    df.timeStyle = .none
    return df
}()

struct MainTabView: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        TabView {
            AIHerbalistChatView()
                .environmentObject(appState)
                .tabItem {
                    Label("Chat", systemImage: "message.fill")
                }
            
            CommunityView()
                .tabItem {
                    Label("Community", systemImage: "person.3.fill")
                }
            
            ProfileView(appState: appState)
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
        .accentColor(AppTheme.colors.sageGreen)
        .background(AppTheme.colors.background)
    }
}

#Preview {
    ProfileView(appState: AppState())
        .environmentObject(AppState())
} 