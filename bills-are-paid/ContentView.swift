//
//  ContentView.swift
//  bills-are-paid
//
//  Created by NullDev on 12/5/25.
//

import SwiftUI

// MARK: - Data Model (move outside ContentView)
struct Expense: Identifiable {
    let id = UUID()
    var name: String
    var amount: Double
}

// MARK: - Main View
struct ContentView: View {

    @State private var paycheck: Double = 0
    @State private var expenses: [Expense] = []
    @State private var showingPaycheckSheet = false
    @State private var showingAddExpenseSheet = false

    // Computed values
    private var totalExpenses: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    private var overUnder: Double {
        paycheck - totalExpenses
    }

    var body: some View {

        NavigationStack {
            VStack {
                // Inside the top header VStack, add this line:
                VStack(spacing: 16) {
                    HStack {
                        Label("Paycheck planner", systemImage: "checkmark.app")
                            .font(Font.largeTitle.bold())
                            .fontWidth(.condensed)
                            .foregroundColor(.blue)

                        Spacer()

                        NavigationLink {
                            SettingsView()
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.title2)
                                .padding(8)
                                .background(Circle().fill(Color(.systemGray5)))
                        }
                    }
                    .padding(.horizontal)

                    // ... rest of your header ...
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
                    Button("Add Paycheck") { showingPaycheckSheet = true }
                        .buttonStyle(.borderedProminent)
                        .cornerRadius(25)
                }
                .padding()

                Spacer()

                // Dynamic Expense List
                List {
                    ForEach(expenses) { expense in
                        HStack {
                            Label(
                                expense.name,
                                systemImage: "dollarsign.bank.building"
                            )
                            Spacer()
                            Text(expense.amount, format: .currency(code: "USD"))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                    .onDelete { expenses.remove(atOffsets: $0) }
                }
                .cornerRadius(25)
                .listStyle(.inset)

                // Add Expense Button
                Button("Add Expense") {
                    showingAddExpenseSheet = true
                }
                .buttonStyle(.borderedProminent)
                .cornerRadius(25)
                .frame(width: 200, height: 60)
                .padding()
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
        }
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
                }

                Section("Data") {
                    Button("Clear All Expenses") {
                        // We'll connect this later
                    }
                    .foregroundColor(.red)
                }

                Section("About") {
                    HStack {
                        Text("Version: Alpha-0.1")
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

