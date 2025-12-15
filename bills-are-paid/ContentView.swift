//
//  ContentView.swift
//  bills-are-paid
//
//  Created by NullDev on 12/5/25.
//

// persistence
import SwiftData
// UI
import SwiftUI

// MARK: - Data Model (move outside ContentView)
struct Expense: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var amount: Double
    var isPaid: Bool = false
}

// MARK: - Main View
struct ContentView: View {

    @State private var paycheck: Double = 0
    @State private var expenses: [Expense] = []
    @State private var showingPaycheckSheet = false
    @State private var showingAddExpenseSheet = false

    @AppStorage("expensesData") private var expensesData: Data = Data()

    @AppStorage("appTheme") private var appTheme = "system"  // "system", "light", "dark"

    private var selectedColorScheme: ColorScheme? {
        switch appTheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil  // system
        }
    }

    private func loadExpenses() {
        guard !expensesData.isEmpty else { return }
        if let decoded = try? JSONDecoder().decode(
            [Expense].self,
            from: expensesData
        ) {
            expenses = decoded
        }
    }

    private func saveExpenses() {
        if let data = try? JSONEncoder().encode(expenses) {
            expensesData = data
        }
    }

    // Computed values
    private var totalExpenses: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    private var overUnder: Double {
        paycheck - totalExpenses
    }

    var body: some View {

        // MARK: NavStack
        NavigationStack {
            VStack {
                VStack(spacing: 16) {
                    HStack {
                        Label("Paycheck planner", systemImage: "checkmark.app")
                            .font(Font.largeTitle.bold())
                            .fontWidth(.condensed)
                            .foregroundColor(.blue)

                        Spacer()

                    }
                    .padding(.horizontal)

                }

                // Paycheck summary
                HStack {
                    VStack(alignment: .leading) {
                        Label(
                            "Paycheck: \(paycheck, format: .currency(code: "USD"))",
                            systemImage: "dollarsign.circle"
                        )
                        Label(
                            "Over / Under: \(overUnder, format: .currency(code: "USD"))",
                            systemImage: overUnder >= 0
                                ? "checkmark.circle" : "exclamationmark.circle"
                        )
                        .foregroundColor(overUnder >= 0 ? .green : .red)
                    }
                    Spacer()
                    HStack(spacing: 8) {
                        Button("Paycheck") { showingPaycheckSheet = true }
                            .buttonStyle(.borderedProminent)
                            .cornerRadius(25)

                        Button("Clear") { paycheck = 0 }
                            .buttonStyle(.bordered)
                            .cornerRadius(25)
                    }
                }
                .padding()

                Spacer()

                // MARK: List display with check box when paid expense.

                // Dynamic Expense List
                List {
                    ForEach(expenses.indices, id: \.self) { index in  // Use indices for .onDelete compatibility
                        HStack {
                            // Custom label with icon and name (to allow strikethrough on name)
                            HStack {
                                Image(systemName: "dollarsign.bank.building")  // Your icon
                                Text(expenses[index].name)
                                    .strikethrough(expenses[index].isPaid)  // Strikethrough when paid
                                    .foregroundStyle(
                                        expenses[index].isPaid
                                            ? .gray : .primary
                                    )  // Gray when paid
                            }

                            Spacer()

                            Text(
                                expenses[index].amount,
                                format: .currency(code: "USD")
                            )
                            .strikethrough(expenses[index].isPaid)  // Strikethrough when paid
                            .foregroundStyle(
                                expenses[index].isPaid ? .gray : .secondary
                            )  // Gray when paid; .secondary for unpaid to match original

                            // Checkbox button
                            Button(
                                action: {
                                    expenses[index].isPaid.toggle()  // Toggle paid status
                                },
                                label: {
                                    Image(
                                        systemName: expenses[index].isPaid
                                            ? "checkmark.square.fill" : "square"
                                    )
                                }
                            )
                            .buttonStyle(.plain)  // No background or border
                            .foregroundStyle(.blue)
                            .font(.system(size: 16))  // Fixed syntax; optional size adjustment
                        }
                        .padding(.vertical, 8)
                    }
                    .onDelete { expenses.remove(atOffsets: $0) }
                }
                .cornerRadius(25)
                .padding(20)
                .listStyle(.inset)
                .shadow(
                    color: .gray,
                    radius: 3,
                    x: 2,
                    y: 4
                )

                // MARK: Lower buttons
                HStack {
                    // Add Expense Button
                    Button("Add Expense") {
                        showingAddExpenseSheet = true
                    }
                    .buttonStyle(.borderedProminent)
                    .cornerRadius(25)
                    .frame(width: 200, height: 60)
                    
                    Spacer()
                    
                    // MARK: menu settings
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .padding(8)
                            .background(Circle().fill(Color(.systemGray5)))
                    }
                }
            }
            // MARK: - Sheets (correctly placed here)
            .sheet(isPresented: $showingPaycheckSheet) {
                PaycheckInputSheet(paycheck: $paycheck)
            }
            .sheet(isPresented: $showingAddExpenseSheet) {
                AddExpenseView { newExpense in
                    expenses.append(newExpense)
                }
            }
            .onAppear { loadExpenses() }
            .onChange(of: expenses) { oldValue, newValue in
                saveExpenses()
            }
        }
        .preferredColorScheme(selectedColorScheme)
    }
}

// MARK: - Add Expense Sheet
struct AddExpenseView: View {
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var amount = ""

    var onSave: (Expense) -> Void

    var body: some View {
        NavigationStack {
            Form {
                TextField("Expense name (e.g. Rent)", text: $name)
                TextField("Amount", text: $amount)
                    .keyboardType(.decimalPad)
            }
            .navigationTitle("New Expense")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let amt = Double(amount), !name.isEmpty {
                            onSave(Expense(name: name, amount: amt))
                            dismiss()
                        }
                    }
                    .disabled(name.isEmpty || Double(amount) == nil)
                }
            }
        }
    }
}

// MARK: - Paycheck Sheet (slightly cleaned up)
struct PaycheckInputSheet: View {
    @Binding var paycheck: Double
    @Environment(\.dismiss) var dismiss
    @State private var inputText = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Paycheck amount", text: $inputText)
                    .keyboardType(.decimalPad)
            }
            .navigationTitle("Add Paycheck")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let value = Double(inputText) {
                            paycheck = value
                        }
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}

// MARK: - Settings Screen
struct SettingsView: View {
    @AppStorage("currencyCode") private var currencyCode = "USD"
    @AppStorage("appTheme") private var appTheme = "system"

    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    Picker("Currency", selection: $currencyCode) {
                        Text("US Dollar ($)").tag("USD")
                        Text("Euro (€)").tag("EUR")
                        Text("British Pound (£)").tag("GBP")
                        Text("Japanese Yen (¥)").tag("JPY")
                    }
                    Picker("Appearance", selection: $appTheme) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                }

//                Section("Data") {
//                    Button("Clear All Expenses") {
//                        // We'll connect this later
//                    }
//                    .foregroundColor(.red)
//                }

                Section("About") {
                    HStack {
                        Text("Version: Alpha-1.0")
                        Spacer()
                        Text("1.0")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Made by: NullXee")
                        Spacer()
                        Text("You")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
