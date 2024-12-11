import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: TransactionStore
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var selectedCurrency: Currency
    @State private var showingAddGoal = false
    @State private var showingShareSheet = false
    @State private var csvString: String = ""
    
    init(store: TransactionStore) {
        _selectedCurrency = State(initialValue: store.settings.currency)
    }
    
    var body: some View {
        NavigationView {
            List {
                // Валюта
                Section("Валюта") {
                    Picker("Выберите валюту", selection: $selectedCurrency) {
                        ForEach(Currency.allCases, id: \.self) { currency in
                            HStack {
                                Text(currency.rawValue)
                                Text(currency.name)
                            }
                            .tag(currency)
                        }
                    }
                    .onChange(of: selectedCurrency) { newValue in
                        store.updateCurrency(newValue)
                    }
                }
                
                // Тема
                Section("Внешний вид") {
                    Toggle("Темная тема", isOn: $isDarkMode)
                }
                
                // Финансовые цели
                Section(header: Text("Финансовые цели"), footer: Text("Нажмите +, чтобы добавить новую цель")) {
                    ForEach(store.settings.financialGoals) { goal in
                        GoalRow(goal: goal)
                    }
                    
                    Button(action: { showingAddGoal = true }) {
                        Label("Добавить цель", systemImage: "plus")
                    }
                }
                
                // Экспорт данных
                Section("Экспорт") {
                    Button(action: prepareAndShareCSV) {
                        Label("Поделиться данными", systemImage: "square.and.arrow.up")
                    }
                }
            }
            .navigationTitle("Настройки")
            .navigationBarItems(leading: Button("Закрыть") { dismiss() })
            .sheet(isPresented: $showingAddGoal) {
                AddGoalView()
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(items: [generateCSV()])
            }
        }
        .onAppear {
            selectedCurrency = store.settings.currency
        }
    }
    
    private func prepareAndShareCSV() {
        showingShareSheet = true
    }
    
    private func generateCSV() -> URL {
        var csvString = "Дата,Категория,Тип,Сумма,Заметка\n"
        
        for transaction in store.transactions {
            let row = "\(formatDate(transaction.date)),\(transaction.category.name),\(transaction.type),\(transaction.amount),\(transaction.note)\n"
            csvString.append(row)
        }
        
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("transactions.csv")
        try? csvString.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

struct GoalRow: View {
    @EnvironmentObject var store: TransactionStore
    let goal: FinancialGoal
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text(goal.name)
                        .font(.headline)
                    Text("Срок: \(formatDate(goal.deadline))")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
                Menu {
                    Button(action: { showingEditSheet = true }) {
                        Label("Изменить", systemImage: "pencil")
                    }
                    Button(role: .destructive, action: { showingDeleteAlert = true }) {
                        Label("Удалить", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.gray)
                }
            }
            
            HStack {
                Text("\(Int(goal.progress * 100))%")
                    .font(.caption)
                Spacer()
                Text("\(goal.currentAmount, specifier: "%.0f") / \(goal.targetAmount, specifier: "%.0f")")
                    .font(.caption)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(goal.progress >= 1 ? Color.green : Color.blue)
                        .frame(width: min(CGFloat(goal.progress) * geometry.size.width, geometry.size.width), height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
            
            if goal.progress >= 1 {
                Text("Цель достигнута! 🎉")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditGoalView(goal: goal)
        }
        .alert("Удалить цель?", isPresented: $showingDeleteAlert) {
            Button("Отмена", role: .cancel) { }
            Button("Удалить", role: .destructive) {
                store.deleteGoal(goal)
            }
        } message: {
            Text("Это действие нельзя отменить")
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct EditGoalView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: TransactionStore
    let goal: FinancialGoal
    
    @State private var name: String
    @State private var targetAmount: String
    @State private var currentAmount: String
    @State private var deadline: Date
    @State private var selectedCategory: Category?
    
    var incomeCategories: [Category] {
        store.categories.filter { $0.type == .income }
    }
    
    init(goal: FinancialGoal) {
        self.goal = goal
        _name = State(initialValue: goal.name)
        _targetAmount = State(initialValue: String(goal.targetAmount))
        _currentAmount = State(initialValue: String(goal.currentAmount))
        _deadline = State(initialValue: goal.deadline)
        _selectedCategory = State(initialValue: goal.category)
    }
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Название цели", text: $name)
                TextField("Целевая сумма", text: $targetAmount)
                    .keyboardType(.decimalPad)
                TextField("Текущая сумма", text: $currentAmount)
                    .keyboardType(.decimalPad)
                DatePicker("Срок", selection: $deadline, displayedComponents: .date)
                
                Picker("Источник дохода", selection: $selectedCategory) {
                    Text("Без категории").tag(nil as Category?)
                    ForEach(incomeCategories) { category in
                        Text(category.name).tag(category as Category?)
                    }
                }
            }
            .navigationTitle("Изменить цель")
            .navigationBarItems(
                leading: Button("Отмена") { dismiss() },
                trailing: Button("Сохранить") {
                    if let targetAmount = Double(targetAmount),
                       let currentAmount = Double(currentAmount),
                       !name.isEmpty {
                        let updatedGoal = FinancialGoal(
                            id: goal.id,
                            name: name,
                            targetAmount: targetAmount,
                            currentAmount: currentAmount,
                            deadline: deadline,
                            category: selectedCategory
                        )
                        store.updateGoal(updatedGoal)
                        dismiss()
                    }
                }
            )
        }
    }
}

struct AddGoalView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: TransactionStore
    @State private var name = ""
    @State private var targetAmount = ""
    @State private var deadline = Date()
    @State private var selectedCategory: Category?
    
    var incomeCategories: [Category] {
        store.categories.filter { $0.type == .income }
    }
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Название цели", text: $name)
                TextField("Целевая сумма", text: $targetAmount)
                    .keyboardType(.decimalPad)
                DatePicker("Срок", selection: $deadline, displayedComponents: .date)
                
                Picker("Источник дохода", selection: $selectedCategory) {
                    Text("Без категории").tag(nil as Category?)
                    ForEach(incomeCategories) { category in
                        Text(category.name).tag(category as Category?)
                    }
                }
            }
            .navigationTitle("Новая цель")
            .navigationBarItems(
                leading: Button("Отмена") { dismiss() },
                trailing: Button("Сохранить") {
                    if let amount = Double(targetAmount), !name.isEmpty {
                        let goal = FinancialGoal(
                            name: name,
                            targetAmount: amount,
                            currentAmount: 0,
                            deadline: deadline,
                            category: selectedCategory
                        )
                        store.addGoal(goal)
                        dismiss()
                    }
                }
            )
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
} 