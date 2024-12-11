//
//  ContentView.swift
//  Finance
//
//  Created by Хамза Кабылбек on 11.12.2024.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: TransactionStore
    @State private var showingAddTransaction = false
    @State private var showingAnalytics = false
    @State private var showingSettings = false
    @State private var selectedTransactionType: TransactionType = .expense
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Мой бюджет")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    // Баланс
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Текущий баланс")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Text(store.formatAmount(store.totalBalance))
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Быстрые действия
                    HStack(spacing: 16) {
                        ActionButton(title: "Доход", icon: "plus", color: .green) {
                            selectedTransactionType = .income
                            showingAddTransaction = true
                        }
                        
                        ActionButton(title: "Расход", icon: "minus", color: .red) {
                            selectedTransactionType = .expense
                            showingAddTransaction = true
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.top)
                
                // Последние транзакции
                VStack(alignment: .leading, spacing: 16) {
                    Text("Последние транзакции")
                        .font(.headline)
                        .padding(.horizontal)
                        .padding(.top, 24)
                    
                    List {
                        ForEach(store.transactions) { transaction in
                            TransactionRowNew(transaction: transaction)
                                .padding(.vertical, 4)
                        }
                        .onDelete { indexSet in
                            indexSet.forEach { index in
                                store.deleteTransaction(store.transactions[index])
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Color.white)
            .navigationBarItems(
                leading: Button(action: { showingAnalytics = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "chart.pie.fill")
                            .font(.system(size: 18))
                        Text("Аналитика")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.blue.opacity(0.1))
                    )
                    .foregroundColor(.blue)
                },
                trailing: Button(action: { showingSettings = true }) {
                    Image(systemName: "gear")
                        .font(.system(size: 18))
                }
            )
            .sheet(isPresented: $showingAddTransaction) {
                AddTransactionView(type: selectedTransactionType)
                    .environmentObject(store)
            }
            .fullScreenCover(isPresented: $showingAnalytics) {
                AnalyticsView()
                    .environmentObject(store)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(store: store)
                    .environmentObject(store)
            }
        }
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Circle()
                    .fill(color)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Image(systemName: icon)
                            .font(.caption)
                            .foregroundColor(.white)
                    )
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
}

struct TransactionRowNew: View {
    @EnvironmentObject var store: TransactionStore
    let transaction: Transaction
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: transaction.category.icon)
                .font(.title2)
                .foregroundColor(Color(hex: transaction.category.color))
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.category.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                if !transaction.note.isEmpty {
                    Text(transaction.note)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            Text("\(transaction.type == .income ? "+" : "-")\(store.formatAmount(transaction.amount))")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(transaction.type == .income ? .green : .red)
        }
        .padding(.vertical, 4)
        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
        .listRowBackground(Color.clear)
    }
}

#Preview {
    ContentView()
        .environmentObject(TransactionStore())
}
