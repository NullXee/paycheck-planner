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
    var dueDate: Date? = nil
}

// MARK: - Main View
struct ContentView: View {

    @State private var paycheck: Double = 0
    @State private var expenses: [Expense] = []
    @State private var showingPaycheckSheet = false
    @State private var showingAddExpenseSheet = false
    @State private var showingEditExpenseSheet = false
    @State private var expenseBeingEdited: Expense?
    

    @AppStorage("expensesData") private var expensesData: Data = Data()
    @AppStorage("paycheckAmount") private var paycheckStored: Double = 0

    @AppStorage("appTheme") private var appTheme = "system"  // "system", "light", "dark"
    @AppStorage("currencyCode") private var currencyCode = "USD"

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
    
    private var sortedExpenses: [Expense] {
        expenses.sorted { lhs, rhs in
            switch (lhs.dueDate, rhs.dueDate) {
            case let (.some(left), .some(right)):
                return left < right
            case (.none, .some):
                return false
            case (.some, .none):
                return true
            case (.none, .none):
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
        }
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
                    }
                    .padding(.horizontal)

                }

                // Paycheck summary
                HStack {
                    VStack(alignment: .leading) {
                        Label(
                            "Paycheck: \(paycheck, format: .currency(code: currencyCode))",
                            systemImage: "dollarsign.circle"
                        )
                        Label(
                            "Over / Under: \(overUnder, format: .currency(code: currencyCode))",
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
                    ForEach(sortedExpenses) { expense in
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Image(systemName: "dollarsign.bank.building")
                                    Text(expense.name)
                                        .strikethrough(expense.isPaid)
                                        .foregroundStyle(expense.isPaid ? .gray : .primary)
                                }
                                if let due = expense.dueDate {
                                    let isPastDue = !expense.isPaid && due < Date()
                                    Text("Due: \(due, format: .dateTime.month().day().year())")
                                        .font(.caption)
                                        .foregroundStyle(isPastDue ? .red : (expense.isPaid ? .gray : .secondary))
                                }
                            }

                            Spacer()

                            Text(expense.amount, format: .currency(code: currencyCode))
                                .strikethrough(expense.isPaid)
                                .foregroundStyle(expense.isPaid ? .gray : .secondary)

                            Button(action: {
                                if let idx = expenses.firstIndex(where: { $0.id == expense.id }) {
                                    expenses[idx].isPaid.toggle()
                                }
                            }) {
                                Image(systemName: expense.isPaid ? "checkmark.square.fill" : "square")
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.blue)
                            .font(.system(size: 16))
                        }
                        .padding(.vertical, 8)
                        .onTapGesture {
                            expenseBeingEdited = expense
                        }
                    }
                    .onDelete { indexSet in
                        let idsToDelete = indexSet.map { sortedExpenses[$0].id }
                        expenses.removeAll { idsToDelete.contains($0.id) }
                    }
                }
                .cornerRadius(25)
                .padding(20)
                .listStyle(.inset)
                .shadow(
                    color: .gray,
                    radius: 3,
//                    x: 2, // Left/Right
//                    y: 4 // Up/Down
                )

                // MARK: Lower buttons
                HStack(alignment: .center) {
                    Button("Add Expense") {
                        showingAddExpenseSheet = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .frame(height: 44)
                    .cornerRadius(25)

                    // Settings button styled to visually align with Add Expense
                    NavigationLink {
                        SettingsView()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "gearshape.fill")
                            Text("Settings")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .frame(height: 44)
                    .cornerRadius(25)
                }
                .padding(.horizontal, 20)
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
            .sheet(item: $expenseBeingEdited) { expense in
                EditExpenseView(
                    expense: expense,
                    onSave: { updated in
                        if let idx = expenses.firstIndex(where: { $0.id == updated.id }) {
                            expenses[idx] = updated
                        }
                    }
                )
            }
            .onAppear { loadExpenses(); paycheck = paycheckStored }
            .onChange(of: expenses) { oldValue, newValue in
                saveExpenses()
            }
            .onChange(of: paycheck) { oldValue, newValue in
                paycheckStored = newValue
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
    @State private var hasDueDate = false
    @State private var dueDate = Date()

    var onSave: (Expense) -> Void

    var body: some View {
        NavigationStack {
            Form {
                TextField("Expense name (e.g. Rent)", text: $name)
                TextField("Amount", text: $amount)
                    .keyboardType(.decimalPad)
                Toggle("Has Due Date", isOn: $hasDueDate)
                if hasDueDate {
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                }
            }
            .navigationTitle("New Expense")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let amt = Double(amount), !name.isEmpty {
                            var expense = Expense(name: name, amount: amt)
                            if hasDueDate {
                                expense.dueDate = dueDate
                            }
                            onSave(expense)
                            dismiss()
                        }
                    }
                    .disabled(name.isEmpty || Double(amount) == nil)
                }
            }
        }
    }
}

// MARK: - Edit Expense Sheet
struct EditExpenseView: View {
    @Environment(\.dismiss) private var dismiss

    let expense: Expense
    var onSave: (Expense) -> Void

    @State private var name: String = ""
    @State private var amount: String = ""
    @State private var hasDueDate: Bool = false
    @State private var dueDate: Date = Date()
    @State private var isPaid: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Expense name", text: $name)
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                    Toggle("Paid", isOn: $isPaid)
                }
                Section("Due date") {
                    Toggle("Has Due Date", isOn: $hasDueDate)
                    if hasDueDate {
                        DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("Edit Expense")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let amt = Double(amount), !name.isEmpty else { return }
                        var updated = expense
                        updated.name = name
                        updated.amount = amt
                        updated.isPaid = isPaid
                        updated.dueDate = hasDueDate ? dueDate : nil
                        onSave(updated)
                        dismiss()
                    }
                    .disabled(name.isEmpty || Double(amount) == nil)
                }
            }
            .onAppear {
                name = expense.name
                amount = String(expense.amount)
                isPaid = expense.isPaid
                if let existingDue = expense.dueDate {
                    hasDueDate = true
                    dueDate = existingDue
                } else {
                    hasDueDate = false
                    dueDate = Date()
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
