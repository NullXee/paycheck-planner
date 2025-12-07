//
//  ContentView.swift
//  bills-are-paid
//
//  Created by NullDev on 12/5/25.
//

import SwiftUI

// Sets the base value to 0 of each Incime and Expense.
var paycheck: Double = 0  // Total monthly income.
var expenseTotal: Double = 0  // How much the expense is.
var expenseName: String = ""  // Holds the name of the expense.
var expenses: [Any] = []  // Array for all expenses text and total. [Any] will allow both strings and doubles in it.

// Main content \\

struct ContentView: View {
    var body: some View {

        // Label/Header
        ZStack {
            Label("Paycheck planner", systemImage: "creditcard.circle")
                .font(Font.largeTitle)
                .foregroundColor(Color.blue)
        }
        .padding()

        // Paycheck area
        HStack {
            Text("Paycheck: $1420.69")
            //            Text("Paycheck: \(paycheck)")
            Spacer()
            Button("Add Paycheck") {
            }
            .buttonStyle(.bordered)
            .background(Color.blue)
            .foregroundColor(Color.white)
            .shadow(color: Color.black.opacity(0.2), radius: 5)
            .cornerRadius(15)
        }
        .padding()

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
        }
        .padding(20)
    }
}

#Preview {
    ContentView()
}
