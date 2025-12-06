//
//  ContentView.swift
//  bills-are-paid
//
//  Created by NullDev on 12/5/25.
//

import SwiftUI

// Sets the base value to 0 of each Incime and Expense.
var monthlyIncome: Double = 0  // Total monthly income.
var expenseTotal: Double = 0 // How much the expense is.
var expenseName: String = ""  // Holds the name of the expense.
var expenses: [Any] = []  // Array for all expenses text and total. [Any] will allow both strings and doubles in it.

// Main content \\

struct ContentView: View {
    var body: some View {

        // Label/Header
        ZStack {
            Label("Bills are paid", systemImage: "creditcard.circle")
                .font(Font.largeTitle)
                .bold(true)
                .foregroundColor(Color.blue)
        }
        .padding()

        // Add buttons
        // @State var set to false
        HStack {
            Button(action: {
                @State var showIncomeInput = false
            }) {
                Text("Add Income")
            }
            Button(action: {
                @State var showExpenseInput = false
            }) {
                Text("Add Expense")

            }
        }
    }
}

#Preview {
    ContentView()
}
