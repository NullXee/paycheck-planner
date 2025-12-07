//
//  ContentView.swift
//  bills-are-paid
//
//  Created by NullDev on 12/5/25.
//

import SwiftUI

// Out of scope \\

struct ContentView: View {

    // In scope \\
    @State private var paycheck: Double = 0  // Add this
    @State private var showingPaycheckSheet = false
    @State private var paycheckInput = ""
    @State private var expensesTotal: Double = 0
    @State private var expensesName: String = ""
    @State private var expenses: [Any] = []
    @State private var isOverOrUnder: Double = 0

    var body: some View {

        VStack {
            // Label/Header
            ZStack {
                Label("Paycheck planner", systemImage: "creditcard.circle")
                    .font(Font.largeTitle)
                    .foregroundColor(Color.blue)
            }
            .padding()

            // Paycheck area
            HStack {
                VStack(alignment: .leading) {
                    // Returns paycheck
                    Text("Paycheck: \(paycheck)")
                        .font(.system(size: 18))
                    // Returns whats left or is negative
                    Text("Over / Under: \(isOverOrUnder)")
                        .font(.system(size: 14))

                }

                Spacer()

                Button(action: {
                    // Code to execute when button is pressed.
                    showingPaycheckSheet = true
                }) {
                    Text("Add Paycheck")
                }
                .buttonStyle(.bordered)
                .background(Color.blue)
                .foregroundColor(Color.white)
                .cornerRadius(15)
            }
            .padding()
            .glassEffect(in: .rect(cornerRadius: 18))

            Spacer()

            List {
                HStack {
                    Label("Expense:", systemImage: "dollarsign.bank.building")
                    Spacer()
                    Label("$0.00", systemImage: "dollarsign.circle")
                }
            }

            // Add buttons
            HStack {
                Button("Add Expense") {
                }
                .buttonStyle(.bordered)
                .background(Color.blue)
                .foregroundColor(Color.white)
                .shadow(color: Color.black.opacity(0.2), radius: 5)
                .cornerRadius(15)
                .sheet(isPresented: $showingPaycheckSheet) {
                    PaycheckInputSheet(
                        paycheck: $paycheck,
                        isPresented: $showingPaycheckSheet
                    )
                }
            }
            .padding(20)
        }
    }
}

#Preview {
    ContentView()
}

// Add this new view outside of ContentView
struct PaycheckInputSheet: View {
    @Binding var paycheck: Double
    @Binding var isPresented: Bool
    @State private var inputText = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationView {
            Form {
                Section("Enter Paycheck Amount") {
                    TextField("Amount", text: $inputText)
                        .keyboardType(.decimalPad)
                        .focused($isInputFocused)
                }
            }
            .navigationTitle("Add Paycheck")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let amount = Double(inputText) {
                            paycheck = amount
                        }
                        isPresented = false
                    }
                }
            }
            .onAppear {
                isInputFocused = true
            }
        }
    }
}
