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
    var isPinned: Bool = false
    var isRecurringMonthly: Bool = false
    var isRecurringWeekly: Bool = false
}

// MARK: - Main View
struct ContentView: View {

    @State private var paycheck: Double = 0
    @State private var expenses: [Expense] = []
    @State private var showingPaycheckSheet = false
    @State private var showingAddExpenseSheet = false
    @State private var showingEditExpenseSheet = false
    @State private var expenseBeingEdited: Expense?
    @State private var expenseFilter: ExpenseFilter = .all
    

    @AppStorage("expensesData") private var expensesData: Data = Data()
    @AppStorage("paycheckAmount") private var paycheckStored: Double = 0

    @AppStorage("appTheme") private var appTheme = "system"  // "system", "light", "dark"
    @AppStorage("currencyCode") private var currencyCode = "USD"
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

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
    
    // Filters
    enum ExpenseFilter: String, CaseIterable, Identifiable { case all, unpaid, paid; var id: String { rawValue } }

    // Computed values
    private var totalExpenses: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    private var overUnder: Double {
        paycheck - totalExpenses
    }
    
    private var sortedExpenses: [Expense] {
        let base = expenses.filter { exp in
            switch expenseFilter {
            case .all: return true
            case .unpaid: return !exp.isPaid
            case .paid: return exp.isPaid
            }
        }
        return base.sorted { lhs, rhs in
            // Pinned first
            if lhs.isPinned != rhs.isPinned { return lhs.isPinned && !rhs.isPinned }
            // Monthly next
            if lhs.isRecurringMonthly != rhs.isRecurringMonthly { return lhs.isRecurringMonthly && !rhs.isRecurringMonthly }
            // Then by due date
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
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Paycheck Planner")
                                .font(.largeTitle.bold())
                                .foregroundStyle(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing))
                                .padding(.bottom, 4)

                            HStack(spacing: 12) {
                                SummaryCard(title: "Paycheck", value: paycheck, currencyCode: currencyCode, symbol: "dollarsign.circle.fill", tint: .blue)
                                SummaryCard(title: "Over/Under", value: overUnder, currencyCode: currencyCode, symbol: overUnder >= 0 ? "checkmark.circle.fill" : "exclamationmark.circle.fill", tint: overUnder >= 0 ? .green : .red)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top)

                        // Paycheck controls
                        HStack(spacing: 12) {
                            Button {
                                showingPaycheckSheet = true
                            } label: {
                                Label("Set Paycheck", systemImage: "square.and.pencil")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)

                            Button {
                                withAnimation { paycheck = 0 }
                            } label: {
                                Label("Clear", systemImage: "trash")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                        }
                        .padding(.horizontal)

                        // Expenses section
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Label("Expenses", systemImage: "list.bullet.rectangle")
                                    .font(.title3.weight(.semibold))
                                Spacer()
                                Text("\(expenses.filter{ !$0.isPaid }.count) due")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal)
                            
                            Picker("Filter", selection: $expenseFilter) {
                                Text("All").tag(ExpenseFilter.all)
                                Text("Unpaid").tag(ExpenseFilter.unpaid)
                                Text("Paid").tag(ExpenseFilter.paid)
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal)

                            // Carded list look
                            GroupBox {
                                if sortedExpenses.isEmpty {
                                    VStack(spacing: 12) {
                                        Image(systemName: "tray")
                                            .font(.largeTitle)
                                            .foregroundStyle(.secondary)
                                        Text("No expenses")
                                            .font(.headline)
                                            .foregroundStyle(.secondary)
                                        Text("Tap + to add an expense.")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 24)
                                } else {
                                    LazyVStack(spacing: 0) {
                                        let pinned = sortedExpenses.filter { $0.isPinned }
                                        let monthly = sortedExpenses.filter { !$0.isPinned && ($0.isRecurringMonthly || $0.isRecurringWeekly) }
                                        let others = sortedExpenses.filter { !$0.isPinned && !$0.isRecurringMonthly && !$0.isRecurringWeekly }

                                        if !pinned.isEmpty { SectionHeader(title: "Pinned") }
                                        ForEach(pinned) { expense in
                                            ExpenseRow(expense: expense, currencyCode: currencyCode) {
                                                if let idx = expenses.firstIndex(where: { $0.id == expense.id }) {
                                                    expenses[idx].isPaid.toggle()
                                                }
                                            }
                                            .contentShape(Rectangle())
                                            .onTapGesture { expenseBeingEdited = expense }
                                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                                Button(role: .destructive) { expenses.removeAll { $0.id == expense.id } } label: { Label("Delete", systemImage: "trash") }
                                            }
                                            .contextMenu { Button(role: .destructive) { expenses.removeAll { $0.id == expense.id } } label: { Label("Delete", systemImage: "trash") } }
                                            Divider().padding(.leading, 16)
                                        }

                                        if !monthly.isEmpty { SectionHeader(title: "Monthly") }
                                        ForEach(monthly) { expense in
                                            ExpenseRow(expense: expense, currencyCode: currencyCode) {
                                                if let idx = expenses.firstIndex(where: { $0.id == expense.id }) {
                                                    expenses[idx].isPaid.toggle()
                                                }
                                            }
                                            .contentShape(Rectangle())
                                            .onTapGesture { expenseBeingEdited = expense }
                                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                                Button(role: .destructive) { expenses.removeAll { $0.id == expense.id } } label: { Label("Delete", systemImage: "trash") }
                                            }
                                            .contextMenu { Button(role: .destructive) { expenses.removeAll { $0.id == expense.id } } label: { Label("Delete", systemImage: "trash") } }
                                            Divider().padding(.leading, 16)
                                        }

                                        if !others.isEmpty { SectionHeader(title: "All") }
                                        ForEach(others) { expense in
                                            ExpenseRow(expense: expense, currencyCode: currencyCode) {
                                                if let idx = expenses.firstIndex(where: { $0.id == expense.id }) {
                                                    expenses[idx].isPaid.toggle()
                                                }
                                            }
                                            .contentShape(Rectangle())
                                            .onTapGesture { expenseBeingEdited = expense }
                                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                                Button(role: .destructive) { expenses.removeAll { $0.id == expense.id } } label: { Label("Delete", systemImage: "trash") }
                                            }
                                            .contextMenu { Button(role: .destructive) { expenses.removeAll { $0.id == expense.id } } label: { Label("Delete", systemImage: "trash") } }
                                            Divider().padding(.leading, 16)
                                        }
                                    }
                                }
                            }
                            .groupBoxStyle(.automatic)
                            .padding(.horizontal)
                        }

                        Spacer(minLength: 24)
                    }
                }

                // Floating Add button
                Button {
                    showingAddExpenseSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(16)
                        .background(
                            Circle().fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                        )
                }
                .padding()
                .accessibilityLabel("Add Expense")
            }
            .navigationTitle("Overview")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
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
            .fullScreenCover(isPresented: .constant(!hasSeenOnboarding)) {
                OnboardingView(onFinish: { hasSeenOnboarding = true })
            }
            .onAppear { loadExpenses(); paycheck = paycheckStored }
            .onChange(of: expenses) { _, _ in saveExpenses() }
            .onChange(of: paycheck) { _, newValue in paycheckStored = newValue }
            .onReceive(NotificationCenter.default.publisher(for: .deleteExpenseRequested)) { notification in
                if let id = notification.object as? UUID {
                    expenses.removeAll { $0.id == id }
                }
            }
        }
        .preferredColorScheme(selectedColorScheme)
    }
}

private struct SummaryCard: View {
    let title: String
    let value: Double
    let currencyCode: String
    let symbol: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: symbol)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tint)
            Text(value, format: .currency(code: currencyCode))
                .font(.title3.bold())
                .foregroundStyle(.primary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.background)
                .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
        )
    }
}

private struct SectionHeader: View {
    let title: String
    var body: some View {
        HStack {
            Text(title.uppercased())
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .padding(.bottom, 6)
        .background(Color.clear)
    }
}

private struct ExpenseRow: View {
    let expense: Expense
    let currencyCode: String
    var togglePaid: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Image(systemName: "dollarsign.bank.building")
                        .foregroundStyle(.blue)
                    Text(expense.name)
                        .fontWeight(.medium)
                        .strikethrough(expense.isPaid)
                        .foregroundStyle(expense.isPaid ? .gray : .primary)
                    if expense.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                            .padding(.leading, 2)
                    }
                    if expense.isRecurringMonthly {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.caption2)
                            .foregroundStyle(.teal)
                            .padding(.leading, 2)
                    }
                    if expense.isRecurringWeekly {
                        Image(systemName: "repeat")
                            .font(.caption2)
                            .foregroundStyle(.purple)
                            .padding(.leading, 2)
                    }
                }
                if let due = expense.dueDate {
                    let isPastDue = !expense.isPaid && due < Date()
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Due: \(due, format: .dateTime.month().day().year())")
                            .font(.caption)
                            .foregroundStyle(isPastDue ? .red : (expense.isPaid ? .gray : .secondary))
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text(expense.amount, format: .currency(code: currencyCode))
                    .fontWeight(.semibold)
                    .strikethrough(expense.isPaid)
                    .foregroundStyle(expense.isPaid ? .gray : .secondary)
                
                let statusText: String = expense.isPaid ? "Paid" : ( (expense.dueDate ?? Date.distantFuture) < Date() ? "Overdue" : "Upcoming")
                let statusColor: Color = expense.isPaid ? .green : ( (expense.dueDate ?? Date.distantFuture) < Date() ? .red : .blue)
                Text(statusText)
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(statusColor.opacity(0.12)))
                    .foregroundStyle(statusColor)
                
                Button(action: togglePaid) {
                    Label(expense.isPaid ? "Paid" : "Mark Paid", systemImage: expense.isPaid ? "checkmark.square.fill" : "square")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.plain)
                .foregroundStyle(expense.isPaid ? .green : .blue)
            }
            .font(.system(size: 16))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

// MARK: - Add Expense Sheet
struct AddExpenseView: View {
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var amount = ""
    @State private var hasDueDate = false
    @State private var repeatsMonthly = false
    @State private var repeatsWeekly = false
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
                Toggle("Repeats Monthly", isOn: $repeatsMonthly)
                Toggle("Repeats Weekly", isOn: $repeatsWeekly)
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
                            expense.isRecurringMonthly = repeatsMonthly
                            expense.isRecurringWeekly = repeatsWeekly
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
                ToolbarItem(placement: .topBarLeading) {
                    Button(role: .destructive) {
                        NotificationCenter.default.post(name: .deleteExpenseRequested, object: expense.id)
                        dismiss()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
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

// MARK: - Onboarding
struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    var onFinish: () -> Void
    @State private var page = 0
    @AppStorage("currencyCode") private var currencyCode = "USD"
    @AppStorage("appTheme") private var appTheme = "system"

    private let totalPages = 4 // 0..4 inclusive -> 5 pages

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                OnboardingPage(
                    systemImage: "checkmark.app.fill",
                    title: "Plan Your Paycheck",
                    message: "Enter your paycheck and instantly see what's left after bills."
                ).tag(0)

                OnboardingPage(
                    systemImage: "list.bullet.rectangle.portrait.fill",
                    title: "Track Expenses",
                    message: "Add bills, set due dates, and mark them paid with a tap."
                ).tag(1)

                OnboardingPage(
                    systemImage: "pin.fill",
                    title: "Pin Important Bills",
                    message: "Keep priority expenses at the top for quick access."
                ).tag(2)

                OnboardingPage(
                    systemImage: "arrow.triangle.2.circlepath",
                    title: "Repeat Monthly & Weekly",
                    message: "Mark recurring expenses so they stick around automatically."
                ).tag(3)

                QuickStartPage(currencyCode: $currencyCode, appTheme: $appTheme)
                    .tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            VStack(spacing: 12) {
                Button(action: advance) {
                    Text(page < totalPages ? "Continue" : "Get Started")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                        )
                        .foregroundStyle(.white)
                }

                Button("Skip") { finish() }
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 24)
            }
            .padding(.horizontal, 20)
            .background(.ultraThinMaterial)
        }
        .ignoresSafeArea()
    }

    private func advance() {
        if page < totalPages { withAnimation { page += 1 } } else { finish() }
    }

    private func finish() {
        onFinish()
        dismiss()
    }
}

private struct OnboardingPage: View {
    let systemImage: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 40)
            Image(systemName: systemImage)
                .font(.system(size: 72, weight: .bold))
                .foregroundStyle(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing))
                .padding(.bottom, 8)
            Text(title)
                .font(.title).bold()
            Text(message)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 24)
            Spacer()
        }
    }
}

private struct QuickStartPage: View {
    @Binding var currencyCode: String
    @Binding var appTheme: String

    var body: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 40)
            Image(systemName: "wand.and.stars")
                .font(.system(size: 64, weight: .bold))
                .foregroundStyle(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing))
                .padding(.bottom, 8)
            Text("Quick Start")
                .font(.title).bold()
            Text("Choose your preferred currency and appearance. You can change these anytime in Settings.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 24)

            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "dollarsign.circle")
                        .foregroundStyle(.secondary)
                    Picker("Currency", selection: $currencyCode) {
                        Text("US Dollar ($)").tag("USD")
                        Text("Euro (€)").tag("EUR")
                        Text("British Pound (£)").tag("GBP")
                        Text("Japanese Yen (¥)").tag("JPY")
                    }
                    .pickerStyle(.menu)
                }

                HStack {
                    Image(systemName: "paintbrush.fill")
                        .foregroundStyle(.secondary)
                    Picker("Appearance", selection: $appTheme) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                    .pickerStyle(.segmented)
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }
}

extension Notification.Name {
    static let deleteExpenseRequested = Notification.Name("deleteExpenseRequested")
}

