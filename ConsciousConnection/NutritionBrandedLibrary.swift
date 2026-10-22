import Foundation

// Personal on-device product library: no server account, no calorie tracking.
// Values are product reference nutrients per 100 g or 100 ml, not meal totals.
struct NutritionSavedProduct: Codable, Identifiable {
    var name: String
    var brand: String? = nil
    var barcode: String? = nil
    var proteinG: Double? = nil
    var fibreG: Double? = nil
    var carbohydrateG: Double? = nil
    var ironMg: Double? = nil
    var magnesiumMg: Double? = nil
    var b12Micrograms: Double? = nil
    var servingSizeText: String? = nil
    var servingQuantity: Double? = nil
    var servingQuantityUnit: String? = nil
    var productQuantityUnit: String? = nil

    var id: String {
        if let barcode, !barcode.isEmpty { return "barcode:" + barcode }
        return "named:" + Self.key((brand ?? "") + " " + name)
    }

    static func key(_ text: String) -> String {
        text.lowercased().filter { $0.isLetter || $0.isNumber }
    }

    var displayName: String {
        guard let brand, !brand.isEmpty,
              !name.lowercased().hasPrefix(brand.lowercased()) else { return name }
        return "\(brand) \(name)"
    }

    var nutritionDetails: String {
        var parts: [String] = []
        if let proteinG { parts.append(String(format: "protein %.1f g", proteinG)) }
        if let fibreG { parts.append(String(format: "fibre %.1f g", fibreG)) }
        if let ironMg { parts.append(String(format: "iron %.2f mg", ironMg)) }
        if let magnesiumMg { parts.append(String(format: "magnesium %.1f mg", magnesiumMg)) }
        if let b12Micrograms { parts.append(String(format: "B12 %.2f µg", b12Micrograms)) }
        return parts.joined(separator: " · ")
    }

    func rawNutriments() -> [String: Any] {
        var result: [String: Any] = [:]
        if let proteinG { result["proteins_100g"] = proteinG }
        if let fibreG { result["fiber_100g"] = fibreG }
        if let carbohydrateG { result["carbohydrates_100g"] = carbohydrateG }
        if let ironMg { result["iron_100g"] = ironMg / 1000.0 }
        if let magnesiumMg { result["magnesium_100g"] = magnesiumMg / 1000.0 }
        if let b12Micrograms { result["vitamin-b12_100g"] = b12Micrograms / 1_000_000.0 }
        return result
    }

    func rawServingFields() -> [String: Any] {
        var result: [String: Any] = [:]
        if let servingSizeText { result["serving_size"] = servingSizeText }
        if let servingQuantity { result["serving_quantity"] = servingQuantity }
        if let servingQuantityUnit { result["serving_quantity_unit"] = servingQuantityUnit }
        if let productQuantityUnit { result["product_quantity_unit"] = productQuantityUnit }
        return result
    }

    static func fromProduct(name: String, brand: String?, barcode: String?,
                            nutriments: [String: Any]?, productFields: [String: Any]? = nil) -> Self {
        func number(_ dictionary: [String: Any]?, _ key: String) -> Double? {
            if let n = dictionary?[key] as? NSNumber { return n.doubleValue }
            if let s = dictionary?[key] as? String { return Double(s) }
            return nil
        }
        return .init(name: name, brand: brand, barcode: barcode,
            proteinG: number(nutriments, "proteins_100g"),
            fibreG: number(nutriments, "fiber_100g"),
            carbohydrateG: number(nutriments, "carbohydrates_100g"),
            ironMg: number(nutriments, "iron_100g").map { $0 * 1000 },
            magnesiumMg: number(nutriments, "magnesium_100g").map { $0 * 1000 },
            b12Micrograms: number(nutriments, "vitamin-b12_100g").map { $0 * 1_000_000 },
            servingSizeText: productFields?["serving_size"] as? String,
            servingQuantity: number(productFields, "serving_quantity"),
            servingQuantityUnit: productFields?["serving_quantity_unit"] as? String,
            productQuantityUnit: productFields?["product_quantity_unit"] as? String)
    }

    // Migration from previously recorded branded foods in the existing app.
    static func fromStoredJSON(_ dict: [String: Any]) -> Self? {
        guard let name = dict["name"] as? String, !name.isEmpty else { return nil }
        let brand = dict["brand"] as? String
        let barcode = dict["barcode"] as? String
        if (barcode ?? "").isEmpty && (brand ?? "").isEmpty { return nil }
        func number(_ key: String, in data: [String: Any]) -> Double? {
            if let n = data[key] as? NSNumber { return n.doubleValue }
            if let s = data[key] as? String { return Double(s) }
            return nil
        }
        let detail = (dict["nutrition"] as? [String: Any]) ?? dict
        return .init(name: name, brand: brand, barcode: barcode,
            proteinG: number("proteinG", in: detail),
            fibreG: number("fibreG", in: detail),
            carbohydrateG: number("carbohydrateG", in: detail),
            ironMg: number("ironMg", in: detail),
            magnesiumMg: number("magnesiumMg", in: detail),
            b12Micrograms: number("b12Micrograms", in: detail),
            servingSizeText: dict["servingSizeText"] as? String,
            servingQuantity: number("servingQuantity", in: dict),
            servingQuantityUnit: dict["servingQuantityUnit"] as? String,
            productQuantityUnit: dict["productQuantityUnit"] as? String)
    }
}

// UserDefaults is already used for meals and kitchen inventory. The library
// survives app restarts and is available without network access.
enum NutritionBrandedLibrary {
    private static let key = "nutrition.brandedLibrary.v1"
    private static let migrationKey = "nutrition.brandedLibrary.migrated.v1"

    static func load() -> [NutritionSavedProduct] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let products = try? JSONDecoder().decode([NutritionSavedProduct].self, from: data) else { return [] }
        return products.sorted { $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending }
    }

    private static func persist(_ products: [NutritionSavedProduct]) {
        guard let data = try? JSONEncoder().encode(products) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    static func save(_ item: NutritionSavedProduct) {
        guard !item.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let brand = item.brand?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let code = item.barcode?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !brand.isEmpty || !code.isEmpty else { return }
        var products = load()
        let newNameKey = NutritionSavedProduct.key(item.displayName)
        let idx = products.firstIndex { existing in
            if !code.isEmpty, existing.barcode == code { return true }
            return NutritionSavedProduct.key(existing.displayName) == newNameKey
        }
        if let idx {
            let existing = products[idx]
            products[idx] = NutritionSavedProduct(
                name: item.name,
                brand: item.brand ?? existing.brand,
                barcode: item.barcode ?? existing.barcode,
                proteinG: item.proteinG ?? existing.proteinG,
                fibreG: item.fibreG ?? existing.fibreG,
                carbohydrateG: item.carbohydrateG ?? existing.carbohydrateG,
                ironMg: item.ironMg ?? existing.ironMg,
                magnesiumMg: item.magnesiumMg ?? existing.magnesiumMg,
                b12Micrograms: item.b12Micrograms ?? existing.b12Micrograms,
                servingSizeText: item.servingSizeText ?? existing.servingSizeText,
                servingQuantity: item.servingQuantity ?? existing.servingQuantity,
                servingQuantityUnit: item.servingQuantityUnit ?? existing.servingQuantityUnit,
                productQuantityUnit: item.productQuantityUnit ?? existing.productQuantityUnit)
        } else {
            products.append(item)
        }
        persist(products)
    }

    // One-time import of products added before this feature existed.
    @discardableResult
    static func loadWithMigration() -> [NutritionSavedProduct] {
        if !UserDefaults.standard.bool(forKey: migrationKey) {
            func array(_ key: String) -> [[String: Any]] {
                guard let json = UserDefaults.standard.string(forKey: key)?.data(using: .utf8),
                      let rows = try? JSONSerialization.jsonObject(with: json) as? [[String: Any]] else { return [] }
                return rows
            }
            for dict in array("nutrition.userFoods.v1") {
                if let food = NutritionSavedProduct.fromStoredJSON(dict) { save(food) }
            }
            for meal in array("nutrition.loggedMeals.v1") {
                for dict in (meal["ingredients"] as? [[String: Any]]) ?? [] {
                    if let food = NutritionSavedProduct.fromStoredJSON(dict) { save(food) }
                }
            }
            UserDefaults.standard.set(true, forKey: migrationKey)
        }
        return load()
    }
}
