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
    @StateObject private var goalStore = GoalStore()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("Мой бюджет")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.primaryText)
                            .padding(.horizontal)
                            .padding(.top, 8)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Текущий баланс")
                                .captionTextStyle()
                            Text(store.formatAmount(store.totalBalance))
                                .balanceTextStyle()
                        }
                        .padding(.vertical, 20)
                        .padding(.horizontal)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .cardStyle()
                        .padding(.horizontal)
                        
                        HStack(spacing: 16) {
                            Button(action: {
                                selectedTransactionType = .income
                                showingAddTransaction = true
                            }) {
                                HStack {
                                    Image(systemName: "arrow.down")
                                    Text("Доход")
                                }
                            }
                            .transactionButtonStyle(isIncome: true)
                            .frame(width: 140)
                            
                            Button(action: {
                                selectedTransactionType = .expense
                                showingAddTransaction = true
                            }) {
                                HStack {
                                    Image(systemName: "arrow.up")
                                    Text("Расход")
                                }
                            }
                            .transactionButtonStyle(isIncome: false)
                            .frame(width: 140)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.horizontal)
                    }
                    .padding(.top)
                    
//                    VStack(alignment: .leading, spacing: 16) {
//                        Text("Финансовые цели")
//                            .font(.headline)
//                            .foregroundColor(.primaryText)
//                            .padding(.horizontal)
//                        
//                        ForEach(goalStore.goals) { goal in
//                            GoalProgressView(goal: goal)
//                                .padding(.horizontal)
//                        }
//                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Последние транзакции")
                            .font(.headline)
                            .foregroundColor(.primaryText)
                            .padding(.horizontal)
                            .padding(.top, 24)
                        
                        List {
                            ForEach(store.transactions) { transaction in
                                TransactionRowNew(transaction: transaction)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets())
                                    .listRowBackground(Color.clear)
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
            }
            .navigationBarItems(
                leading: Button(action: { showingAnalytics = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "chart.pie.fill")
                        Text("Аналитика")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.accent.opacity(0.1))
                    .cornerRadius(20)
                    .foregroundColor(.accent)
                },
                trailing: Button(action: { showingSettings = true }) {
                    Image(systemName: "gear")
                        .foregroundColor(.primaryText)
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
                SettingsView(goalStore: GoalStore())
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
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [color, color.opacity(0.8)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(12)
            .standardShadow()
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
                    .foregroundColor(.primaryText)
                if !transaction.note.isEmpty {
                    Text(transaction.note)
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                }
            }
            
            Spacer()
            
            Text("\(transaction.type == .income ? "+" : "-")\(store.formatAmount(transaction.amount))")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(transaction.type == .income ? .incomeGreen : .expenseRed)
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .standardShadow()
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

#Preview {
    ContentView()
        .environmentObject(TransactionStore())
}
