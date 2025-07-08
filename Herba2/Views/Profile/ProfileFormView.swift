import SwiftUI

struct ProfileFormView: View {
    let isPrimary: Bool
    let onSave: (Profile) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    
    @State private var name = ""
    @State private var dateOfBirth = Date()
    @State private var allergies: [String] = []
    @State private var chronicConditions: [String] = []
    @State private var medications: [String] = []
    @State private var newAllergy = ""
    @State private var newCondition = ""
    @State private var newMedication = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Basic Information") {
                    TextField("Name", text: $name)
                        .appInputStyle()
                    DatePicker("Date of Birth", selection: $dateOfBirth, displayedComponents: .date)
                        .tint(AppTheme.colors.accent)
                }
                
                Section("Allergies") {
                    ForEach(allergies, id: \.self) { allergy in
                        Text(allergy)
                            .appBody()
                    }
                    .onDelete { indexSet in
                        allergies.remove(atOffsets: indexSet)
                    }
                    
                    HStack {
                        TextField("Add Allergy", text: $newAllergy)
                            .appInputStyle()
                        Button("Add") {
                            if !newAllergy.isEmpty {
                                allergies.append(newAllergy)
                                newAllergy = ""
                            }
                        }
                        .appButtonStyle()
                        .disabled(newAllergy.isEmpty)
                    }
                }
                
                Section("Chronic Conditions") {
                    ForEach(chronicConditions, id: \.self) { condition in
                        Text(condition)
                            .appBody()
                    }
                    .onDelete { indexSet in
                        chronicConditions.remove(atOffsets: indexSet)
                    }
                    
                    HStack {
                        TextField("Add Condition", text: $newCondition)
                            .appInputStyle()
                        Button("Add") {
                            if !newCondition.isEmpty {
                                chronicConditions.append(newCondition)
                                newCondition = ""
                            }
                        }
                        .appButtonStyle()
                        .disabled(newCondition.isEmpty)
                    }
                }
                
                Section("Medications") {
                    ForEach(medications, id: \.self) { medication in
                        Text(medication)
                            .appBody()
                    }
                    .onDelete { indexSet in
                        medications.remove(atOffsets: indexSet)
                    }
                    
                    HStack {
                        TextField("Add Medication", text: $newMedication)
                            .appInputStyle()
                        Button("Add") {
                            if !newMedication.isEmpty {
                                medications.append(newMedication)
                                newMedication = ""
                            }
                        }
                        .appButtonStyle()
                        .disabled(newMedication.isEmpty)
                    }
                }
            }
            .navigationTitle(isPrimary ? "Add Primary Profile" : "Add Family Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.colors.sageGreen)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveProfile()
                    }
                    .foregroundColor(AppTheme.colors.sageGreen)
                    .disabled(name.isEmpty)
                }
            }
            .background(AppTheme.colors.background)
        }
    }
    
    private func saveProfile() {
        guard let userId = appState.currentUser?.id else { return }
        
        let profile = Profile(
            id: UUID().uuidString,
            userId: userId,
            name: name,
            dateOfBirth: dateOfBirth,
            allergies: allergies,
            chronicConditions: chronicConditions,
            medications: medications,
            isPrimaryProfile: isPrimary,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        onSave(profile)
    }
}

#Preview {
    ProfileFormView(isPrimary: true) { _ in }
        .environmentObject(AppState())
} 