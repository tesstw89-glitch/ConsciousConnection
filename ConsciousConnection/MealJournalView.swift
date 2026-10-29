import SwiftUI
import Foundation

// A separate food diary, without quantities or calories.
// This intentionally does not change the kitchen inventory or its ticked selections.
private struct JournalIngredient: Codable, Identifiable {
    var name: String
    var brand: String? = nil
    var barcode: String? = nil
    // Values, when present, are Open Food Facts per-100g reference data.
    var proteinG: Double? = nil
    var fibreG: Double? = nil
    var carbohydrateG: Double? = nil
    var ironMg: Double? = nil
    var magnesiumMg: Double? = nil
    var b12Micrograms: Double? = nil
    // Optional to preserve meal records saved by earlier versions.
    // A portion is a description of what was eaten, not automatically a nutrient calculation.
    var quantityText: String? = nil
    var portionUnit: String? = nil
    // Fields absent from older saved diary entries decode to nil; history is preserved.
    var servingSizeText: String? = nil
    var servingQuantity: Double? = nil        // Open Food Facts normalized quantity
    var servingQuantityUnit: String? = nil     // g or ml
    var productQuantityUnit: String? = nil     // g, kg, ml, l...
    var customUnitSize: Double? = nil         // edible g or ml per egg/slice/piece etc.

    static func defaultUnit(for name: String) -> String {
        let lower = name.lowercased()
        if lower.contains("egg") { return "egg" }
        if lower.contains("bread") || lower.contains("toast") || lower.contains("loaf") { return "slice" }
        return "serving"
    }

    static func positiveNumber(_ text: String?) -> Double? {
        guard let text,
              let number = Double(text.trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: ",", with: ".")),
              number.isFinite, number > 0 else { return nil }
        return number
    }

    var baseUnit: String {
        // OFF _100g nutrient fields are per 100 ml for liquids.
        // Never convert ml to grams or vice versa using an invented density.
        let normalized = (servingQuantityUnit ?? "").lowercased()
        if normalized == "ml" { return "ml" }
        let packageUnit = (productQuantityUnit ?? "").lowercased()
        if ["ml", "l", "cl"].contains(packageUnit) { return "ml" }
        return "g"
    }

    var servingAmount: Double? {
        guard let n = servingQuantity, n.isFinite, n > 0 else { return nil }
        let unit = (servingQuantityUnit ?? "").lowercased()
        guard ["g", "ml"].contains(unit), unit == baseUnit else { return nil }
        return n
    }

    // Count individual items in a declared serving, e.g. "2 slices (80 g)".
    // We only use this when the package provides BOTH the count and the total weight.
    private func itemsPerServing(for unit: String) -> Double? {
        guard let text = servingSizeText?.lowercased(), servingAmount != nil else { return nil }
        let pattern: String
        switch unit {
        case "egg": pattern = #"([0-9]+(?:[.,][0-9]+)?)\s*eggs?\b"#
        case "slice": pattern = #"([0-9]+(?:[.,][0-9]+)?)\s*slices?\b"#
        case "piece": pattern = #"([0-9]+(?:[.,][0-9]+)?)\s*(?:pieces?|biscuits?|bars?)\b"#
        default: return nil
        }
        guard let re = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = re.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let capture = Range(match.range(at: 1), in: text) else { return nil }
        return Self.positiveNumber(String(text[capture]))
    }

    var consumedReferenceAmount: Double? {
        guard let n = Self.positiveNumber(quantityText) else { return nil }
        let unit = portionUnit ?? "serving"
        if unit == baseUnit { return n }
        if unit == "serving", let serving = servingAmount { return n * serving }
        if ["egg", "slice", "piece", "tbsp", "tsp"].contains(unit) {
            if let override = customUnitSize, override.isFinite, override > 0 {
                return n * override
            }
            if let count = itemsPerServing(for: unit), let serving = servingAmount {
                return n * serving / count
            }
        }
        return nil
    }

    var portionScale: Double? {
        guard let amount = consumedReferenceAmount else { return nil }
        return amount / 100.0
    }

    var portionDescription: String {
        guard let amount = Self.positiveNumber(quantityText) else { return "Portion not recorded" }
        let unit = portionUnit ?? "serving"
        let plural = abs(amount - 1) > 0.000001
        let label: String
        switch unit {
        case "egg": label = plural ? "eggs" : "egg"
        case "slice": label = plural ? "slices" : "slice"
        case "piece": label = plural ? "pieces" : "piece"
        case "serving": label = plural ? "servings" : "serving"
        default: label = unit
        }
        let quantity = String(format: "%g", amount)
        if let reference = consumedReferenceAmount {
            return "\(quantity) \(label) (\(String(format: "%g", reference)) \(baseUnit))"
        }
        return "\(quantity) \(label) · nutrient quantity unknown"
    }

    var measuredNutrientSummary: String {
        guard let scale = portionScale else { return "" }
        var parts: [String] = []
        if let proteinG { parts.append(String(format: "protein %.1f g", proteinG * scale)) }
        if let fibreG { parts.append(String(format: "fibre %.1f g", fibreG * scale)) }
        if let carbohydrateG { parts.append(String(format: "carbs %.1f g", carbohydrateG * scale)) }
        if let ironMg { parts.append(String(format: "iron %.2f mg", ironMg * scale)) }
        if let magnesiumMg { parts.append(String(format: "magnesium %.1f mg", magnesiumMg * scale)) }
        if let b12Micrograms { parts.append(String(format: "B12 %.2f µg", b12Micrograms * scale)) }
        return parts.joined(separator: " · ")
    }

    func withStarterPortion() -> Self {
        var updated = self
        let unit = Self.defaultUnit(for: name)
        if (unit == "egg" || unit == "slice"), itemsPerServing(for: unit) != nil {
            updated.quantityText = "1"
            updated.portionUnit = unit
        } else if servingAmount != nil {
            updated.quantityText = "1"
            updated.portionUnit = "serving"
        } else {
            updated.quantityText = (unit == "serving") ? nil : "1"
            updated.portionUnit = unit
        }
        return updated
    }

    var id: String {
        if let barcode, !barcode.isEmpty { return "off:" + barcode }
        return ((brand ?? "") + " " + name).lowercased().filter { $0.isLetter || $0.isNumber }
    }

    var displayName: String {
        guard let brand, !brand.isEmpty, !name.lowercased().hasPrefix(brand.lowercased()) else {
            return name
        }
        return "\(brand) \(name)"
    }

    var nutrientSummary: String {
        var parts: [String] = []
        if let proteinG { parts.append(String(format: "protein %.1f g", proteinG)) }
        if let fibreG { parts.append(String(format: "fibre %.1f g", fibreG)) }
        if let carbohydrateG { parts.append(String(format: "carbs %.1f g", carbohydrateG)) }
        if let ironMg { parts.append(String(format: "iron %.2f mg", ironMg)) }
        if let magnesiumMg { parts.append(String(format: "magnesium %.1f mg", magnesiumMg)) }
        if let b12Micrograms { parts.append(String(format: "B12 %.2f µg", b12Micrograms)) }
        return parts.joined(separator: " · ")
    }

    static func fromOpenFoodFacts(barcode: String, name: String, brand: String?, nutriments: [String: Any]?, productFields: [String: Any]? = nil) -> Self {
        func number(_ key: String) -> Double? {
            guard let value = nutriments?[key] else { return nil }
            if let n = value as? NSNumber { return n.doubleValue }
            if let s = value as? String { return Double(s) }
            return nil
        }
        var food = Self(name: name, brand: brand, barcode: barcode,
                        proteinG: number("proteins_100g"), fibreG: number("fiber_100g"),
                        carbohydrateG: number("carbohydrates_100g"),
                        ironMg: number("iron_100g").map { $0 * 1_000 },
                        magnesiumMg: number("magnesium_100g").map { $0 * 1_000 },
                        b12Micrograms: number("vitamin-b12_100g").map { $0 * 1_000_000 })
        food.servingSizeText = productFields?["serving_size"] as? String
        if let servingNumber = productFields?["serving_quantity"] as? NSNumber {
            food.servingQuantity = servingNumber.doubleValue
        } else if let servingString = productFields?["serving_quantity"] as? String {
            food.servingQuantity = positiveNumber(servingString)
        }
        food.servingQuantityUnit = productFields?["serving_quantity_unit"] as? String
        // Some community records omit the normalized unit while displaying it in serving_size.
        // Infer only g vs ml from an explicit numeric quantity + unit in that label.
        if food.servingQuantityUnit == nil, let servingLabel = food.servingSizeText,
           let regex = try? NSRegularExpression(pattern: #"[0-9]+(?:[.,][0-9]+)?[ ]*(ml|millilitres?|g|grams?)(?:[^a-z]|$)"#, options: .caseInsensitive),
           let match = regex.matches(in: servingLabel,
                    range: NSRange(servingLabel.startIndex..., in: servingLabel)).last,
           let range = Range(match.range(at: 1), in: servingLabel) {
            let labelUnit = String(servingLabel[range]).lowercased()
            food.servingQuantityUnit = labelUnit.hasPrefix("m") ? "ml" : "g"
        }
        food.productQuantityUnit = productFields?["product_quantity_unit"] as? String
        return food
    }
}

// Each favourite is a reusable copy of a meal, NOT another diary entry.
// Stored separately so changing brands does not rewrite a historical meal.
private struct JournalMealTemplate: Codable, Identifiable {
    var id: UUID
    var name: String
    var mealType: String
    var ingredients: [JournalIngredient]
    var savedAt: Date
}

private struct JournalMeal: Codable, Identifiable {
    var id: UUID
    var name: String
    var mealType: String
    var eatenAt: Date
    var ingredients: [JournalIngredient]
}

struct MealJournalView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("nutrition.loggedMeals.v1") private var savedMealsJSON = ""
    @AppStorage("nutrition.savedMealTemplates.v1") private var savedTemplatesJSON = ""
    @AppStorage("nutrition.packdTropicalSmoothieSeeded.v1") private var didSeedPackdSmoothie = false
    // 0 = meal history, 1 = daily nutrition, 2 = favourite meals
    var initialTab: Int = 0
    @State private var activeTab = 0
    @State private var selectedDay = Date()
    @State private var shownMonth = Date()
    @State private var templates: [JournalMealTemplate] = []
    @State private var editingTemplateID: UUID? = nil
    @State private var replacingIngredientID: String? = nil
    @State private var meals: [JournalMeal] = []
    @State private var groqNutritionPayload = ""
    @State private var showingGroqNutrition = false
    @State private var didLoad = false
    @State private var showingEditor = false
    @State private var editingID: UUID? = nil
    @State private var draftName = ""
    @State private var draftType = "Lunch"
    @State private var draftDate = Date()
    @State private var draftIngredients: [JournalIngredient] = []
    @State private var manualIngredient = ""
    @State private var showingProductFinder = false
    @State private var showingJournalBarcodeScanner = false
    @State private var scanningJournalProduct = false
    @State private var journalBarcodeError = ""
    @State private var showingJournalBarcodeError = false

    private let mealTypes = ["Breakfast", "Lunch", "Dinner", "Snack"]
    private let dayCalendar = Calendar.current
    private let accent = Color(red: 0.11, green: 0.48, blue: 0.40)

    init(initialTab: Int = 0) {
        self.initialTab = initialTab
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Picker("Nutrition view", selection: $activeTab) {
                        Text("History").tag(0)
                        Text("Today").tag(1)
                        Text("Saved meals").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .accessibilityLabel("Nutrition: meal history, daily totals or saved meals")

                    if activeTab == 0 {
                        Text("A gentle record of the meals you've enjoyed — not a calorie diary.")
                            .foregroundStyle(.secondary)
                        logNewMealButton
                        Text("My meals")
                            .font(.title2.weight(.bold))
                        if meals.isEmpty {
                            ContentUnavailableView("No meals logged yet", systemImage: "fork.knife",
                                description: Text("Add a meal you've eaten, including meals from previous days."))
                        } else {
                            ForEach(meals.sorted { $0.eatenAt > $1.eatenAt }) { item in
                                mealCard(item)
                            }
                        }
                    } else if activeTab == 1 {
                        dailyNutritionSection
                    } else {
                        savedMealsSection
                    }
                }
                .padding(18)
            }
            .navigationTitle("My Nutrition")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                loadSavedMeals()
                activeTab = initialTab
                selectedDay = Date()
                shownMonth = Date()
            }
            .sheet(isPresented: $showingEditor) { editor }
            .sheet(isPresented: $showingGroqNutrition) {
                NutritionGroqReviewView(payload: groqNutritionPayload)
            }
        }
    }

    private var logNewMealButton: some View {
        Button(action: startNew) {
            Label("Log a meal I've eaten", systemImage: "plus.circle.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(15)
        }
        .buttonStyle(.borderedProminent)
        .tint(accent)
    }

    // Nutrition Calendar v1: visual language adapted from Habit Tracker's
    // CalendarView (month chevrons, circular day markers, today ring).
    private var dailyNutritionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today & your calendar")
                .font(.title2.weight(.bold))
            Text("Tap a day to see the meals and nutrients you've recorded. A partial day is still worth recording.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            monthControls
            calendarGrid
            HStack(spacing: 8) {
                Button("Jump to today") {
                    selectedDay = Date()
                    shownMonth = Date()
                }
                .font(.caption.weight(.semibold))
                Spacer()
                Text("Colour shows meals recorded, not a score")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 2)
            Divider()
            dayDetail
        }
    }

    private var monthControls: some View {
        HStack {
            Button {
                shownMonth = dayCalendar.date(byAdding: .month, value: -1, to: shownMonth) ?? shownMonth
            } label: {
                Image(systemName: "chevron.left")
                    .frame(width: 42, height: 42)
                    .background(Color(.secondarySystemGroupedBackground), in: Circle())
            }
            .accessibilityLabel("Previous month")
            Spacer()
            Text(shownMonth.formatted(.dateTime.month(.wide).year()))
                .font(.headline)
            Spacer()
            Button {
                shownMonth = dayCalendar.date(byAdding: .month, value: 1, to: shownMonth) ?? shownMonth
            } label: {
                Image(systemName: "chevron.right")
                    .frame(width: 42, height: 42)
                    .background(Color(.secondarySystemGroupedBackground), in: Circle())
            }
            .disabled(dayCalendar.isDate(shownMonth, equalTo: Date(), toGranularity: .month))
            .accessibilityLabel("Next month")
        }
        .tint(accent)
    }

    private var calendarGrid: some View {
        let start = dayCalendar.date(from: dayCalendar.dateComponents([.year, .month], from: shownMonth)) ?? shownMonth
        let firstWeekday = dayCalendar.component(.weekday, from: start)
        let leading = (firstWeekday - dayCalendar.firstWeekday + 7) % 7
        let numberOfDays = dayCalendar.range(of: .day, in: .month, for: start)?.count ?? 30
        let weekdayNames = dayCalendar.veryShortStandaloneWeekdaySymbols
        return VStack(spacing: 12) {
            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { index in
                    Text(weekdayNames[(dayCalendar.firstWeekday - 1 + index) % 7])
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 6) {
                ForEach(0..<(leading + numberOfDays), id: \.self) { index in
                    if index < leading {
                        Color.clear.frame(height: 43)
                    } else if let day = dayCalendar.date(byAdding: .day, value: index - leading, to: start) {
                        dayButton(day)
                    }
                }
            }
        }
    }

    private func dayButton(_ date: Date) -> some View {
        let count = mealsOn(date).count
        let today = dayCalendar.isDateInToday(date)
        let selected = dayCalendar.isDate(date, inSameDayAs: selectedDay)
        let future = dayCalendar.startOfDay(for: date) > dayCalendar.startOfDay(for: Date())
        return Button { selectedDay = date } label: {
            ZStack {
                Circle().fill(count == 0 ? Color(.secondarySystemGroupedBackground) : accent.opacity(min(0.23 + 0.20 * Double(count), 0.85)))
                Circle().stroke(selected ? accent : (today ? accent.opacity(0.6) : Color.clear), lineWidth: selected ? 2.5 : 1.5)
                VStack(spacing: 0) {
                    Text("\(dayCalendar.component(.day, from: date))")
                        .font(.subheadline.weight(today ? .bold : .regular))
                    if count > 0 {
                        Circle().fill(accent).frame(width: 4, height: 4)
                    }
                }
                .foregroundStyle(.primary)
            }
            .frame(height: 43)
        }
        .buttonStyle(.plain)
        .opacity(future ? 0.35 : 1)
        .disabled(future)
        .accessibilityLabel("\(date.formatted(date: .abbreviated, time: .omitted)), \(count) meals recorded")
    }

    private func mealsOn(_ date: Date) -> [JournalMeal] {
        meals.filter { dayCalendar.isDate($0.eatenAt, inSameDayAs: date) }
            .sorted { $0.eatenAt < $1.eatenAt }
    }

    private var dayDetail: some View {
        let dayMeals = mealsOn(selectedDay)
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(dayCalendar.isDateInToday(selectedDay) ? "Today" : selectedDay.formatted(date: .complete, time: .omitted))
                        .font(.title3.weight(.bold))
                    Text("\(dayMeals.count) \(dayMeals.count == 1 ? "meal" : "meals") recorded")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button { startNew(on: selectedDay) } label: {
                    Label("Log meal", systemImage: "plus")
                }
                .buttonStyle(.bordered)
                .disabled(dayCalendar.startOfDay(for: selectedDay) > dayCalendar.startOfDay(for: Date()))
            }
            ForEach(["Breakfast", "Lunch", "Dinner"], id: \.self) { type in
                HStack {
                    Image(systemName: dayMeals.contains(where: { $0.mealType == type }) ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(dayMeals.contains(where: { $0.mealType == type }) ? accent : Color.secondary)
                    Text(type)
                    Spacer()
                    Text(dayMeals.filter { $0.mealType == type }.map(\.name).joined(separator: ", "))
                        .lineLimit(1)
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }
            .padding(.vertical, 2)
            if !dayMeals.isEmpty {
                Text("Recorded nutrients")
                    .font(.headline)
                dailyNutrientCards(dayMeals)
                Button {
                    groqNutritionPayload = groqDayPayload(dayMeals)
                    showingGroqNutrition = true
                } label: {
                    Label("Groq: what could I add today?", systemImage: "sparkles")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(accent)
                Text("Calculated from recorded portions and available product values. Partial means one or more ingredients don't have that nutrient recorded. These are not dietary targets or complete intake estimates.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("Meals on this day")
                    .font(.headline)
                ForEach(dayMeals) { item in mealCard(item) }
            } else {
                ContentUnavailableView("No meals recorded", systemImage: "leaf",
                    description: Text("You can add a meal for this day whenever you're ready."))
            }
        }
    }

    private struct DayMetric: Identifiable {
        let title: String
        let amount: Double
        let unit: String
        let known: Int
        let total: Int
        let precision: Int
        var id: String { title }
    }

    private func dailyMetrics(_ dayMeals: [JournalMeal]) -> [DayMetric] {
        let foods = dayMeals.flatMap { $0.ingredients }
        let nutrients: [(String, String, Int, (JournalIngredient) -> Double?)] = [
            ("Protein", "g", 1, { $0.proteinG }),
            ("Fibre", "g", 1, { $0.fibreG }),
            ("Carbohydrates", "g", 1, { $0.carbohydrateG }),
            ("Iron", "mg", 2, { $0.ironMg }),
            ("Magnesium", "mg", 1, { $0.magnesiumMg }),
            ("B12", "µg", 2, { $0.b12Micrograms })
        ]
        return nutrients.map { label, unit, digits, field in
            var amount = 0.0
            var count = 0
            for food in foods {
                if let scale = food.portionScale, let number = field(food), number.isFinite {
                    amount += number * scale
                    count += 1
                }
            }
            return DayMetric(title: label, amount: amount, unit: unit,
                             known: count, total: foods.count, precision: digits)
        }
    }

    private func dailyNutrientCards(_ dayMeals: [JournalMeal]) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(dailyMetrics(dayMeals)) { metric in
                VStack(alignment: .leading, spacing: 6) {
                    Text(metric.title).font(.subheadline.weight(.semibold))
                    if metric.known == 0 {
                        Text("Not available").font(.footnote).foregroundStyle(.secondary)
                    } else {
                        Text("\(String(format: "%.*f", metric.precision, metric.amount)) \(metric.unit)")
                            .font(.title3.weight(.bold))
                            .monospacedDigit()
                            .foregroundStyle(accent)
                    }
                    Text(metric.known == metric.total && metric.total > 0
                         ? "All ingredients reported" : "Partial · \(metric.known)/\(metric.total) ingredients")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(13)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // Use measured per-portion contributions and explicit data coverage.
    // The language model never receives guessed daily target percentages.
    private func groqDayPayload(_ dayMeals: [JournalMeal]) -> String {
        let dateLabel = selectedDay.formatted(date: .complete, time: .omitted)
        let mealLines = dayMeals.map { meal in
            let ingredients = meal.ingredients.map { item in
                let contributed = item.measuredNutrientSummary
                let fact = contributed.isEmpty
                    ? "no reliable calculated nutrient contribution"
                    : contributed
                return "   - \(item.displayName): \(item.portionDescription); \(fact)"
            }.joined(separator: "\n")
            return "• \(meal.mealType): \(meal.name)\n\(ingredients.isEmpty ? "   - ingredients not recorded" : ingredients)"
        }.joined(separator: "\n")
        let metricLines = dailyMetrics(dayMeals).map { metric in
            let recorded = metric.known > 0
                ? String(format: "%.*f %@", metric.precision, metric.amount, metric.unit)
                : "unknown"
            return "• \(metric.title): \(recorded); coverage \(metric.known)/\(metric.total) ingredients. These are recorded subtotals, not complete intake totals."
        }.joined(separator: "\n")
        let pantry = NutritionView.selectedFoodsForGroq()
        let pantryLines = pantry.isEmpty
            ? "No currently selected pantry ingredients were provided. Ask me to tick what's actually available."
            : pantry.map { "• " + $0 }.joined(separator: "\n")
        let loggedTypes = Set(dayMeals.map { $0.mealType })
        let omitted = ["Breakfast", "Lunch", "Dinner"].filter { !loggedTypes.contains($0) }
        let opportunities = omitted.isEmpty ? "Breakfast, lunch and dinner all logged." : "Not logged yet: " + omitted.joined(separator: ", ") + ". This does not mean they were skipped."
        return """
        NUTRITION JOURNAL — \(dateLabel)
        Meals actually logged:
        \(mealLines)

        Recorded nutrient contributions (only values with usable portion and source data):
        \(metricLines)

        \(opportunities)

        Ingredients checked as currently available at home:
        \(pantryLines)

        My goals are practical meals featuring protein, fibre-rich carbohydrates, magnesium, vitamin B12 and iron. I don't track calories.
        
        IMPORTANT: The nutrient figures above are only the recorded, portion-calculated SUBTOTALS for ingredients with data. Missing vitamin/mineral fields mean NOT REPORTED, not zero. Please cautiously estimate what the unreported vitamins/minerals might contribute, using general food-composition knowledge and the named logged foods and actual portions. Where sensible, include other relevant nutrients such as vitamin C, folate, calcium and potassium. Do not treat these estimates as measured or label-verified data.
        
        For each priority nutrient, distinguish (a) recorded numeric contributions, (b) plausible additional estimates from logged foods, and (c) what remains too uncertain to calculate. Avoid double counting a nutrient that is already reported for the same food. If quantities are unclear, discuss likely sources qualitatively rather than inventing weights or exact totals. Do not assume a branded food is fortified unless its name or reported information supports that. A generic egg or bread reference is only an approximation of that product.
        
        Then help me judge which nutrients might usefully be added through the rest of the day, with concrete suggestions using ONLY ingredients currently checked as available at home. Do not use calorie counts, numerical target percentages or diagnose a deficiency. Missing diary entries do not prove a meal was skipped.
        """
    }

    private var savedMealsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Favourite meals")
                .font(.title2.weight(.bold))
            Text("Save a meal from History once, then log it again with different portions or brands. Your previous entry stays unchanged.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if templates.isEmpty {
                ContentUnavailableView("No saved meals yet", systemImage: "heart.text.square",
                    description: Text("Open History and choose ‘Save as favourite’ on a meal you've logged."))
            } else {
                ForEach(templates.sorted { $0.savedAt > $1.savedAt }) { item in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(item.name).font(.headline)
                        Text("\(item.mealType) · \(item.ingredients.count) ingredients")
                            .font(.caption).foregroundStyle(.secondary)
                        ForEach(item.ingredients) { ingredient in
                            Text("• \(ingredient.displayName) — \(ingredient.portionDescription)")
                                .font(.caption)
                        }
                        HStack {
                            Button { repeatTemplate(item) } label: {
                                Label("Log again", systemImage: "arrow.clockwise")
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(accent)
                            Spacer()
                            Menu {
                                Button("Edit favourite", systemImage: "pencil") { editTemplate(item) }
                                Button("Delete favourite", systemImage: "trash", role: .destructive) {
                                    templates.removeAll { $0.id == item.id }
                                    storeTemplates()
                                }
                            } label: {
                                Label("Options", systemImage: "ellipsis.circle")
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(15)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
                }
            }
        }
    }

    private func mealCard(_ item: JournalMeal) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.name).font(.headline)
                    Text("\(item.mealType) · \(item.eatenAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 4)
                Button("Repeat") { repeatMeal(item) }
                    .font(.subheadline)
                Button("Edit") { edit(item) }
                    .font(.subheadline)
                    .font(.subheadline)
            }
            ForEach(item.ingredients) { food in
                VStack(alignment: .leading, spacing: 3) {
                    Text("• \(food.displayName)")
                        .font(.subheadline)
                    Text(food.portionDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if !food.measuredNutrientSummary.isEmpty {
                        Text("For this recorded portion: \(food.measuredNutrientSummary)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    } else if !food.nutrientSummary.isEmpty {
                        Text("Nutrient total unavailable without a known weight or volume")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            if let summary = recordedNutrientSummary(item.ingredients) {
                Text("Recorded nutrient contributions: \(summary)")
                    .font(.caption.weight(.medium))
                Text("Partial if any ingredient or nutrient is missing data. Calculated from reported per-100 g / 100 ml values.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            if item.ingredients.isEmpty {
                Text("No ingredients recorded")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack {
                Spacer()
                Menu {
                    Button { edit(item) } label: {
                        Label("Edit meal", systemImage: "pencil")
                    }
                    Button { saveTemplate(from: item) } label: {
                        Label("Save as favourite", systemImage: "heart")
                    }
                    Button { repeatMeal(item) } label: {
                        Label("Log again", systemImage: "arrow.clockwise")
                    }
                    Button(role: .destructive) { delete(item) } label: {
                        Label("Delete meal", systemImage: "trash")
                    }
                } label: {
                    Label("More", systemImage: "ellipsis.circle")
                        .font(.caption)
                }
            }
        }
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }

    private func recordedNutrientSummary(_ foods: [JournalIngredient]) -> String? {
        let nutrients: [(String, String, (JournalIngredient) -> Double?)] = [
            ("protein", "g", { $0.proteinG }),
            ("fibre", "g", { $0.fibreG }),
            ("carbs", "g", { $0.carbohydrateG }),
            ("iron", "mg", { $0.ironMg }),
            ("magnesium", "mg", { $0.magnesiumMg }),
            ("B12", "µg", { $0.b12Micrograms })
        ]
        var parts: [String] = []
        for (name, unit, value) in nutrients {
            var sum = 0.0
            var count = 0
            for food in foods {
                if let scale = food.portionScale, let nutrient = value(food) {
                    sum += nutrient * scale
                    count += 1
                }
            }
            if count > 0 {
                let precision = (name == "iron" || name == "B12") ? "%.2f" : "%.1f"
                parts.append("\(name) \(String(format: precision, sum)) \(unit) [\(count)/\(foods.count) ingredients]")
            }
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    private var editor: some View {
        NavigationStack {
            Form {
                Section("The meal") {
                    TextField("Meal name, e.g. eggs on toast", text: $draftName)
                        .textInputAutocapitalization(.sentences)
                    Picker("Meal", selection: $draftType) {
                        ForEach(mealTypes, id: \.self) { Text($0).tag($0) }
                    }
                    if editingTemplateID == nil {
                        DatePicker("When you ate it", selection: $draftDate, in: ...Date(),
                                   displayedComponents: [.date, .hourAndMinute])
                    }
                }
                Section {
                    Button {
                        replacingIngredientID = nil
                        showingProductFinder = true
                    } label: {
                        Label("Search branded ingredients", systemImage: "magnifyingglass")
                    }
                    Button {
                        replacingIngredientID = nil
                        showingJournalBarcodeScanner = true
                    } label: {
                        Label("Scan an ingredient barcode", systemImage: "barcode.viewfinder")
                    }
                    .disabled(scanningJournalProduct)
                    if scanningJournalProduct {
                        ProgressView("Looking up scanned ingredient…")
                    }
                    HStack(spacing: 10) {
                        TextField("Or add an ingredient by name", text: $manualIngredient)
                            .textInputAutocapitalization(.words)
                            .onSubmit(addManualIngredient)
                        Button(action: addManualIngredient) {
                            Image(systemName: "plus.circle.fill").font(.title3)
                        }
                        .disabled(manualIngredient.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .accessibilityLabel("Add named ingredient")
                    }
                } header: {
                    Text("Ingredients")
                } footer: {
                    Text("Search uses Open Food Facts. You can also add eggs, vegetables, leftovers or anything the database doesn't list.")
                }
                if !draftIngredients.isEmpty {
                    Section("In this meal") {
                        ForEach($draftIngredients) { $food in
                            HStack(alignment: .top, spacing: 8) {
                                VStack(alignment: .leading, spacing: 7) {
                                    Text(food.displayName)
                                    JournalPortionInput(food: $food)
                                    Button {
                                        replacingIngredientID = food.id
                                        showingProductFinder = true
                                    } label: {
                                        Label("Swap brand or product", systemImage: "arrow.left.arrow.right")
                                            .font(.caption)
                                    }
                                    .buttonStyle(.borderless)
                                    if !food.measuredNutrientSummary.isEmpty {
                                        Text("For this portion: \(food.measuredNutrientSummary)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    } else if !food.nutrientSummary.isEmpty {
                                        Text("Nutrients unavailable for this portion until its weight or volume is known")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                Button(role: .destructive) {
                                    draftIngredients.removeAll { $0.id == food.id }
                                } label: { Image(systemName: "xmark.circle.fill") }
                                    .buttonStyle(.borderless)
                                    .accessibilityLabel("Remove \(food.displayName)")
                            }
                        }
                    }
                }
                Section {
                    Button(action: saveDraft) {
                        Text(editingTemplateID != nil ? "Save favourite" : (editingID == nil ? "Save meal" : "Save changes"))
                            .frame(maxWidth: .infinity)
                            .fontWeight(.semibold)
                    }
                    .disabled(draftName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                } footer: {
                    Text("Nutrients are calculated for the amount you record when weight/volume and database values are known. Missing nutrients are never counted as zero. No calories are tracked.")
                }
            }
            .navigationTitle(editingTemplateID != nil ? "Edit favourite" : (editingID == nil ? "Log a meal" : "Edit meal"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { showingEditor = false }
                }
            }
            .sheet(isPresented: $showingJournalBarcodeScanner) {
                MealBarcodeScanner { code in
                    Task { await addScannedJournalIngredient(code) }
                }
            }
            .alert("Barcode lookup", isPresented: $showingJournalBarcodeError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(journalBarcodeError)
            }
            .sheet(isPresented: $showingProductFinder) {
                JournalFoodFinder { product in
                    selectProduct(product)
                }
            }
        }
    }

    @MainActor
    private func addScannedJournalIngredient(_ code: String) async {
        guard !scanningJournalProduct else { return }
        scanningJournalProduct = true
        defer { scanningJournalProduct = false }
        do {
            let product = try await MealBarcodeProducts.lookup(code)
            let ingredient = JournalIngredient.fromOpenFoodFacts(
                barcode: product.barcode, name: product.name,
                brand: product.brand, nutriments: product.nutriments,
                productFields: product.rawProduct
            )
            selectProduct(ingredient)
        } catch {
            journalBarcodeError = error.localizedDescription
            showingJournalBarcodeError = true
        }
    }

    private func selectProduct(_ product: JournalIngredient) {
        saveBrandedJournalIngredient(product)
        if let target = replacingIngredientID,
           let index = draftIngredients.firstIndex(where: { $0.id == target }) {
            let previous = draftIngredients[index]
            var replacement = product.withStarterPortion()
            // Keep the number and unit the user entered. Do NOT carry an old brand's
            // custom edible weight into a new product; it may be different.
            replacement.quantityText = previous.quantityText ?? replacement.quantityText
            replacement.portionUnit = previous.portionUnit ?? replacement.portionUnit
            replacement.customUnitSize = nil
            if !draftIngredients.enumerated().contains(where: { $0.offset != index && $0.element.id == replacement.id }) {
                draftIngredients[index] = replacement
            } else {
                draftIngredients.remove(at: index)
            }
        } else if !draftIngredients.contains(where: { $0.id == product.id }) {
            draftIngredients.append(product.withStarterPortion())
        }
        replacingIngredientID = nil
    }

    private func saveTemplate(from item: JournalMeal) {
        let name = item.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let existing = templates.firstIndex {
            $0.name.caseInsensitiveCompare(name) == .orderedSame && $0.mealType == item.mealType
        }
        let updated = JournalMealTemplate(id: existing.map { templates[$0].id } ?? UUID(),
            name: name, mealType: item.mealType, ingredients: item.ingredients, savedAt: Date())
        if let existing { templates[existing] = updated } else { templates.append(updated) }
        storeTemplates()
        activeTab = 2
    }

    private func repeatMeal(_ item: JournalMeal) {
        editingID = nil
        editingTemplateID = nil
        draftName = item.name
        draftType = item.mealType
        draftDate = Date()
        draftIngredients = item.ingredients
        manualIngredient = ""
        replacingIngredientID = nil
        showingEditor = true
    }

    private func repeatTemplate(_ item: JournalMealTemplate) {
        editingID = nil
        editingTemplateID = nil
        draftName = item.name
        draftType = item.mealType
        draftDate = Date()
        draftIngredients = item.ingredients
        manualIngredient = ""
        replacingIngredientID = nil
        showingEditor = true
    }

    private func editTemplate(_ item: JournalMealTemplate) {
        editingID = nil
        editingTemplateID = item.id
        draftName = item.name
        draftType = item.mealType
        draftDate = Date()
        draftIngredients = item.ingredients
        manualIngredient = ""
        replacingIngredientID = nil
        showingEditor = true
    }

    private func startNew(on day: Date) {
        startNew()
        // The historical day is retained, at an ordinary daytime hour.
        if !dayCalendar.isDateInToday(day), let atNoon = dayCalendar.date(bySettingHour: 12, minute: 0, second: 0, of: day) {
            draftDate = atNoon
        }
    }

    private func startNew() {
        editingID = nil
        editingTemplateID = nil
        replacingIngredientID = nil
        draftName = ""
        draftType = "Lunch"
        draftDate = Date()
        draftIngredients = []
        manualIngredient = ""
        showingEditor = true
    }

    private func edit(_ item: JournalMeal) {
        editingTemplateID = nil
        replacingIngredientID = nil
        editingID = item.id
        draftName = item.name
        draftType = item.mealType
        draftDate = item.eatenAt
        draftIngredients = item.ingredients
        manualIngredient = ""
        showingEditor = true
    }

    private func addManualIngredient() {
        let name = manualIngredient.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        let ingredient = JournalIngredient(name: name)
        if !draftIngredients.contains(where: { $0.id == ingredient.id }) {
            draftIngredients.append(ingredient.withStarterPortion())
        }
        manualIngredient = ""
    }

    private func saveDraft() {
        let name = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        if let templateID = editingTemplateID {
            let updated = JournalMealTemplate(id: templateID, name: name,
                mealType: draftType, ingredients: draftIngredients, savedAt: Date())
            if let index = templates.firstIndex(where: { $0.id == templateID }) {
                templates[index] = updated
            }
            storeTemplates()
            for food in draftIngredients { saveBrandedJournalIngredient(food) }
            showingEditor = false
            return
        }
        let newEntry = JournalMeal(id: editingID ?? UUID(), name: name,
                                   mealType: draftType, eatenAt: draftDate,
                                   ingredients: draftIngredients)
        if let idx = meals.firstIndex(where: { $0.id == newEntry.id }) {
            meals[idx] = newEntry
        } else {
            meals.append(newEntry)
        }
        storeMeals()
        for food in draftIngredients { saveBrandedJournalIngredient(food) }
        showingEditor = false
    }

    private func delete(_ item: JournalMeal) {
        meals.removeAll { $0.id == item.id }
        storeMeals()
    }

    private func loadSavedMeals() {
        guard !didLoad else { return }
        didLoad = true
        loadTemplates()
        seedPackdTropicalSmoothieIfNeeded()
        guard let bytes = savedMealsJSON.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([JournalMeal].self, from: bytes) else { return }
        meals = decoded
    }

    private func loadTemplates() {
        guard let data = savedTemplatesJSON.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([JournalMealTemplate].self, from: data) else { return }
        templates = decoded
    }

    // Add this personal recipe only once. It is a reusable favourite, not a diary
    // entry: never invent an eaten date, alter existing meals, or re-add after deletion.
    private func seedPackdTropicalSmoothieIfNeeded() {
        guard !didSeedPackdSmoothie else { return }
        // A damaged saved library must not be replaced with an empty one.
        if !savedTemplatesJSON.isEmpty {
            guard let data = savedTemplatesJSON.data(using: .utf8),
                  (try? JSONDecoder().decode([JournalMealTemplate].self, from: data)) != nil
            else { return }
        }

        let title = "PACK'D Tropical Smoothie"
        if !templates.contains(where: { $0.name.caseInsensitiveCompare(title) == .orderedSame }) {
            let ingredients: [JournalIngredient] = [
                JournalIngredient(name: "Banana", quantityText: "50", portionUnit: "g"),
                JournalIngredient(name: "Frozen avocado", brand: "PACK'D", quantityText: "30", portionUnit: "g"),
                JournalIngredient(name: "Frozen mango", brand: "PACK'D", quantityText: "45", portionUnit: "g"),
                JournalIngredient(name: "Frozen pineapple", brand: "Sainsbury's", quantityText: "30", portionUnit: "g"),
                JournalIngredient(name: "Milk", quantityText: "250", portionUnit: "ml", productQuantityUnit: "ml"),
                JournalIngredient(name: "Chia seeds", quantityText: "5", portionUnit: "g"),
                JournalIngredient(name: "Honey", quantityText: "21", portionUnit: "g")
            ]
            templates.append(JournalMealTemplate(id: UUID(), name: title,
                mealType: "Snack", ingredients: ingredients, savedAt: Date()))
            storeTemplates()
        }
        didSeedPackdSmoothie = true
    }

    private func storeTemplates() {
        guard let data = try? JSONEncoder().encode(templates),
              let json = String(data: data, encoding: .utf8) else { return }
        savedTemplatesJSON = json
    }

    private func saveBrandedJournalIngredient(_ food: JournalIngredient) {
        NutritionBrandedLibrary.save(NutritionSavedProduct(
            name: food.name, brand: food.brand, barcode: food.barcode,
            proteinG: food.proteinG, fibreG: food.fibreG,
            carbohydrateG: food.carbohydrateG, ironMg: food.ironMg,
            magnesiumMg: food.magnesiumMg, b12Micrograms: food.b12Micrograms,
            servingSizeText: food.servingSizeText,
            servingQuantity: food.servingQuantity,
            servingQuantityUnit: food.servingQuantityUnit,
            productQuantityUnit: food.productQuantityUnit
            ))
    }

    private func storeMeals() {
        guard let bytes = try? JSONEncoder().encode(meals),
              let json = String(data: bytes, encoding: .utf8) else { return }
        savedMealsJSON = json
    }
}

// Editable amount and unit: "1 egg", "2 slices", "150 g" and so on.
// No nutrition conversion is inferred for counted units without a known edible weight.
private struct JournalPortionInput: View {
    @Binding var food: JournalIngredient

    private let units: [(name: String, value: String)] = [
        ("Servings", "serving"), ("Eggs", "egg"), ("Slices", "slice"),
        ("Grams", "g"), ("Millilitres", "ml"), ("Pieces", "piece"),
        ("Tablespoons", "tbsp"), ("Teaspoons", "tsp")
    ]
    private let presets: [(value: Double, label: String)] = [
        (0.25, "¼"), (0.5, "½"), (1.0, "1"), (1.5, "1½"), (2.0, "2")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            if let label = food.servingSizeText, !label.isEmpty {
                Text("Pack's serving: \(label)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 10) {
                TextField("Amount", text: Binding(
                    get: { food.quantityText ?? "" },
                    set: { food.quantityText = $0 }
                ))
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
                .frame(width: 85)
                .accessibilityLabel("Amount for \(food.displayName)")

                Picker("Unit", selection: Binding(
                    get: { food.portionUnit ?? "serving" },
                    set: { food.portionUnit = $0 }
                )) {
                    ForEach(units, id: \.value) { unit in
                        Text(unit.name).tag(unit.value)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .accessibilityLabel("Portion unit for \(food.displayName)")
                Spacer(minLength: 0)
            }
            if food.servingAmount != nil {
                HStack(spacing: 5) {
                    ForEach(0..<presets.count, id: \.self) { idx in
                        Button(presets[idx].label) {
                            food.portionUnit = "serving"
                            food.quantityText = String(format: "%g", presets[idx].value)
                        }
                        .buttonStyle(.bordered)
                        .font(.caption)
                        .tint(.primary)
                    }
                }
                Text("Or type any decimal, e.g. 0.75 servings")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            if ["egg", "slice", "piece", "tbsp", "tsp"].contains(food.portionUnit ?? "")
                && food.consumedReferenceAmount == nil {
                HStack(spacing: 6) {
                    Text("\(food.baseUnit) per \(food.portionUnit ?? "item")")
                        .font(.caption)
                    TextField("From label or weighed", text: Binding(
                        get: { food.customUnitSize.map { String(format: "%g", $0) } ?? "" },
                        set: { food.customUnitSize = JournalIngredient.positiveNumber($0) }
                    ))
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 95)
                }
                Text("Enter an edible weight/volume for each item to calculate its nutrients. Not the packet weight.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            if let reference = food.consumedReferenceAmount {
                Text("Amount used: \(String(format: "%g", reference)) \(food.baseUnit)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            } else if food.portionUnit == "serving" && food.servingAmount == nil {
                Text("This product has no recorded serving weight. Select grams/ml or enter a known item weight for nutrient calculations.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else if food.portionUnit == "g" && food.baseUnit == "ml"
                        || food.portionUnit == "ml" && food.baseUnit == "g" {
                Text("Cannot convert grams and millilitres without a known density. Choose the matching unit.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct JournalSearchHit: Identifiable {
    var id: String
    var name: String
    var brand: String?
    var displayName: String {
        guard let brand, !brand.isEmpty, !name.lowercased().hasPrefix(brand.lowercased()) else { return name }
        return "\(brand) \(name)"
    }
}

private struct JournalFoodFinder: View {
    @Environment(\.dismiss) private var dismiss
    let onSelect: (JournalIngredient) -> Void
    @State private var query = ""
    @State private var localBrandedFoods: [NutritionSavedProduct] = []
    @State private var searchingOnlineFoods = false
    @State private var results: [JournalSearchHit] = []
    @State private var errorMessage: String? = nil
    @State private var isSearching = false
    @State private var isFetching = false
    @State private var searchTimes: [Date] = []
    @State private var queryCache: [String: [JournalSearchHit]] = [:]

    private var filteredLocalBrandedFoods: [NutritionSavedProduct] {
        let phrase = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !phrase.isEmpty else { return localBrandedFoods }
        return localBrandedFoods.filter {
            $0.displayName.localizedStandardContains(phrase) ||
            ($0.barcode?.contains(phrase) ?? false)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 10) {
                Text(searchingOnlineFoods
                    ? "Find a new product through Open Food Facts (internet required)."
                    : "Search branded foods you've used before — even offline.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    TextField(searchingOnlineFoods ? "e.g. Co-op wholemeal bread" : "Search my saved branded foods", text: $query)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .submitLabel(.search)
                        .onSubmit { if searchingOnlineFoods { search() } }
                        .textFieldStyle(.roundedBorder)
                    if searchingOnlineFoods {
                        Button("Search") { search() }
                            .buttonStyle(.borderedProminent)
                            .disabled(isSearching || isFetching || query.trimmingCharacters(in: .whitespacesAndNewlines).count < 2)
                    }
                }
                Button {
                    searchingOnlineFoods.toggle()
                    results = []
                    errorMessage = nil
                    if !searchingOnlineFoods { localBrandedFoods = NutritionBrandedLibrary.loadWithMigration() }
                } label: {
                    Label(searchingOnlineFoods ? "Back to my saved foods" : "Search Open Food Facts for something new",
                          systemImage: searchingOnlineFoods ? "clock.arrow.circlepath" : "globe")
                        .font(.subheadline.weight(.semibold))
                }
                .disabled(isSearching || isFetching)

                if searchingOnlineFoods {
                    if isSearching { ProgressView("Finding products…") }
                    if isFetching { ProgressView("Checking nutrition information…") }
                    if let errorMessage {
                        Text(errorMessage).font(.footnote).foregroundStyle(.secondary)
                    }
                    List(results) { hit in
                        Button {
                            Task { await select(hit) }
                        } label: {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(hit.displayName).foregroundStyle(.primary)
                                Text("Tap to add to this meal").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .disabled(isFetching)
                    }
                    .listStyle(.plain)
                } else {
                    if filteredLocalBrandedFoods.isEmpty {
                        ContentUnavailableView("No saved branded foods", systemImage: "tray",
                            description: Text("Scan a barcode or use Search Open Food Facts to add products to your library."))
                    }
                    List(filteredLocalBrandedFoods) { product in
                        Button {
                            onSelect(JournalIngredient.fromOpenFoodFacts(barcode: product.barcode ?? "",
                            name: product.name, brand: product.brand,
                            nutriments: product.rawNutriments(),
                            productFields: product.rawServingFields()))
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(product.displayName).foregroundStyle(.primary)
                                if !product.nutritionDetails.isEmpty {
                                    Text("Per 100 g / 100 ml: \(product.nutritionDetails)")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                if let serving = product.servingSizeText, !serving.isEmpty {
                                    Text("Serving: \(serving)").font(.caption2).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
                Link("Food data: Open Food Facts contributors · ODbL",
                     destination: URL(string: "https://world.openfoodfacts.org/terms-of-use")!)
                    .font(.caption2)
                Text("Saved products stay on this iPhone. Missing nutrients aren't counted as zero.")
                    .font(.caption2).foregroundStyle(.secondary)
            }
            .padding(16)
            .navigationTitle(searchingOnlineFoods ? "Search Open Food Facts" : "My saved branded foods")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear { localBrandedFoods = NutritionBrandedLibrary.loadWithMigration() }
        }
    }

    private func search() {
        let phrase = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard phrase.count >= 2, !isSearching, !isFetching else { return }
        let cacheKey = phrase.lowercased()
        if let cached = queryCache[cacheKey] {
            results = cached
            errorMessage = cached.isEmpty ? "No matches. Try a shorter name or add it manually." : nil
            return
        }
        let now = Date()
        searchTimes = searchTimes.filter { now.timeIntervalSince($0) < 60 }
        guard searchTimes.count < 8 else {
            errorMessage = "Too many searches. Try again in a minute or add the ingredient manually."
            return
        }
        searchTimes.append(now)
        isSearching = true
        errorMessage = nil
        results = []

        var components = URLComponents(string: "https://search.openfoodfacts.org/search")!
        components.queryItems = [
            URLQueryItem(name: "q", value: phrase),
            URLQueryItem(name: "page_size", value: "12"),
            URLQueryItem(name: "langs", value: "en"),
            URLQueryItem(name: "fields", value: "code,product_name,brands")
        ]
        guard let url = components.url else {
            isSearching = false
            errorMessage = "Couldn't build the search request."
            return
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 20
        request.setValue("ConsciousConnection/1.0 (https://github.com/tesstw89-glitch/ConsciousConnection)", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        Task {
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse,
                      (200...299).contains(http.statusCode) else {
                    let status = (response as? HTTPURLResponse)?.statusCode ?? -1
                    throw NSError(domain: "MealJournalSearch", code: status,
                                  userInfo: [NSLocalizedDescriptionKey: "Food search returned HTTP \(status). Please try again."])
                }
                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let hits = json["hits"] as? [[String: Any]] else {
                    throw NSError(domain: "MealJournalSearch", code: -2,
                                  userInfo: [NSLocalizedDescriptionKey: "Unexpected food search response."])
                }
                func stringValue(_ input: Any?) -> String {
                    if let value = input as? String { return value.trimmingCharacters(in: .whitespacesAndNewlines) }
                    if let dictionary = input as? [String: Any] {
                        for lang in ["en", "en-gb", "en_GB"] {
                            if let value = dictionary[lang] as? String, !value.isEmpty { return value }
                        }
                        return dictionary.values.compactMap { $0 as? String }.first ?? ""
                    }
                    return ""
                }
                var seen = Set<String>()
                let found: [JournalSearchHit] = hits.compactMap { hit in
                    let row = (hit["_source"] as? [String: Any]) ?? hit
                    let barcode = stringValue(row["code"])
                    guard !barcode.isEmpty, barcode.count <= 20,
                          barcode.unicodeScalars.allSatisfy({ CharacterSet.decimalDigits.contains($0) }),
                          seen.insert(barcode).inserted else { return nil }
                    let english = stringValue(row["product_name_en"])
                    let name = english.isEmpty ? stringValue(row["product_name"]) : english
                    guard !name.isEmpty else { return nil }
                    let brand = stringValue(row["brands"])
                    return JournalSearchHit(id: barcode, name: name,
                                            brand: brand.isEmpty ? nil : brand)
                }
                await MainActor.run {
                    results = found
                    queryCache[cacheKey] = found
                    errorMessage = found.isEmpty ? "No matching products found. Try a shorter name, or enter it manually." : nil
                    isSearching = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isSearching = false
                }
            }
        }
    }

    @MainActor
    private func select(_ hit: JournalSearchHit) async {
        guard !isFetching else { return }
        isFetching = true
        defer { isFetching = false }
        var nutrients: [String: Any]? = nil
        var productFields: [String: Any]? = nil
        if let url = URL(string: "https://world.openfoodfacts.org/api/v2/product/\(hit.id).json?fields=code,product_name,brands,nutriments,serving_size,serving_quantity,serving_quantity_unit,product_quantity_unit") {
            var request = URLRequest(url: url)
            request.timeoutInterval = 15
            request.setValue("ConsciousConnection/1.0 (https://github.com/tesstw89-glitch/ConsciousConnection)", forHTTPHeaderField: "User-Agent")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                if let http = response as? HTTPURLResponse,
                   (200...299).contains(http.statusCode),
                   let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let product = json["product"] as? [String: Any] {
                    nutrients = product["nutriments"] as? [String: Any]
                    productFields = product
                }
            } catch {
                // The product can still be logged if the nutrition lookup fails.
                print("Meal journal: nutrient lookup failed: \(error.localizedDescription)")
            }
        }
        onSelect(.fromOpenFoodFacts(barcode: hit.id, name: hit.name,
                                    brand: hit.brand, nutriments: nutrients,
                                    productFields: productFields))
        dismiss()
    }
}
