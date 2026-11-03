import SwiftUI
import Security
import Foundation

// Personal-device Groq prototype: the user's own key is stored in iOS Keychain,
// never in source, UserDefaults, or an Xcode project file.
// For distribution to other users, use a server-side authenticated proxy instead.
private enum NutritionGroqKeychain {
    private static let service = "com.tess.ConsciousConnection.NutritionGroq"
    private static let account = "userApiKey"

    private static var query: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: service,
         kSecAttrAccount as String: account]
    }

    static func read() -> String? {
        var attributes = query
        attributes[kSecReturnData as String] = true
        attributes[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(attributes as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data,
              let key = String(data: data, encoding: .utf8), !key.isEmpty else { return nil }
        return key
    }

    static func save(_ raw: String) -> Bool {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("gsk_"), trimmed.count > 15,
              let data = trimmed.data(using: .utf8) else { return false }
        SecItemDelete(query as CFDictionary)
        var attributes = query
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        return SecItemAdd(attributes as CFDictionary, nil) == errSecSuccess
    }

    static func remove() {
        SecItemDelete(query as CFDictionary)
    }
}

private enum NutritionGroqError: LocalizedError {
    case message(String)
    var errorDescription: String? {
        switch self { case .message(let text): return text }
    }
}


// Groq numbers refer to the consumed portion and are NEVER verified label data.
struct NutritionGroqIngredientEstimate: Codable, Identifiable {
    let mealID: String
    let ingredientIndex: Int
    let proteinG: Double?
    let fibreG: Double?
    let carbohydrateG: Double?
    let ironMg: Double?
    let magnesiumMg: Double?
    let b12Micrograms: Double?
    let confidence: String
    let note: String
    var id: String { mealID + ":" + String(ingredientIndex) }
    var hasNumbers: Bool {
        [proteinG, fibreG, carbohydrateG, ironMg, magnesiumMg, b12Micrograms].contains { $0 != nil }
    }
}

struct NutritionGroqEstimateResponse: Codable {
    let ingredients: [NutritionGroqIngredientEstimate]
}

struct NutritionGroqStoredEstimate: Codable {
    let mealID: String
    let ingredientIndex: Int
    let portionSignature: String
    let estimate: NutritionGroqIngredientEstimate
}

private enum NutritionGroqService {
    static func review(_ payload: String, key: String) async throws -> String {
        guard let url = URL(string: "https://api.groq.com/openai/v1/chat/completions") else {
            throw NutritionGroqError.message("Groq API address is invalid.")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("Bearer " + key, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let system = """
        NUTRIENT-ESTIMATES-V2: Approximate missing micronutrients without overwriting reported data.
        You are a warm, supportive and evidence-conscious nutrition planning companion. Respond in UK English, in about 300–450 words when there are several recorded foods, and more briefly when there aren't.
        This is a partial food diary, NOT a clinical dietary assessment. Don't discuss calories, weight loss or dieting.

        The user's logged meals include ingredient names, brands where recorded, portions, known nutrient contributions and data coverage. The recorded daily figures are SUBTOTALS of ingredients with known nutrient values, not an exhaustive account of intake. A missing nutrient field means unknown, not zero. A recorded zero can be genuine and should not be replaced with an estimate.

        Your job is to bridge missing nutrient information using cautious GENERIC FOOD ESTIMATES, not to repeat that nothing can be known. Give particular attention to protein, fibre-rich carbohydrates, iron, magnesium and vitamin B12; mention other materially relevant vitamins/minerals (e.g. calcium, vitamin C, folate) if there are reasonable clues.

        RULES FOR ESTIMATING:
        - Use sound general food-composition knowledge of a comparable ordinary food, its edible form, and preparation method when known; NEVER claim to have queried CoFID, USDA or any live reference data. These are model-generated estimates, not verified database measurements.
        - If the amount or edible weight is known (e.g. 150 g cooked lentils, one medium egg), you MAY give a sensible, rounded numerical range for a missing nutrient and say it is a rough estimate. Do not supply spurious decimal precision or exact numbers unsupported by the log.
        - If an item is logged by count without a weight, you MAY use an openly stated typical edible-weight assumption for familiar units such as one medium egg or a slice of bread, with LOW or MODERATE confidence. If the item/portion is too vague (e.g. 'some curry', 'a bowl'), do NOT fabricate grams or give numerical totals.
        - For fortified cereals, milk alternatives and branded packaged products, NEVER assume particular fortification levels. You may discuss typical baseline nutrients for that food type, but mark B12, iron, etc. from unverified fortification as UNKNOWN.
        - Only estimate MISSING nutrient contributions; do not estimate an entire meal and add that to the known subtotal (double counting). Never replace a recorded product measurement with a generic guess. Clearly separate source-derived numbers from estimates.
        - Don't infer ingredients omitted from the meal (oil, sauces, seasoning, vegetables, etc.). If the label is insufficiently specific, be modest.
        - If an entire day or nutrient is too poorly recorded for a numeric range, present a qualitative reading and state why. Don't claim intake is low or that the user has a deficiency purely because the log is sparse.
        - Don't compare intake against personalised clinical targets or prescribe supplements. Do not use numerical target percentages.

        OUTPUT FORMAT:
        1) **What you've logged** — a couple of grounded observations and known contributions.
        2) **What the missing nutrients might add** — for the key nutrients, distinguish 'Recorded', 'Estimated' and 'Unknown'. Give short, defensible approximate ranges only if supported by portion assumptions and clarify low confidence as needed. If the estimation is primarily qualitative, that's fine.
        3) **What might help next** — two specific, feasible suggestions using ONLY ingredients explicitly ticked as currently available. Explain the nutrients they would likely add; do not invent kitchen stock. If none are ticked, ask for the pantry to be updated.

        Never misrepresent a model estimate as a tested nutrient value. The goal is useful, non-judgemental meal planning, not perfect nutritional accounting.
        """
        let body: [String: Any] = [
            "model": "openai/gpt-oss-120b",
            "reasoning_effort": "low",
            "include_reasoning": false,
            "temperature": 0.3,
            "max_completion_tokens": 1300,
            "messages": [
                ["role": "system", "content": system],
                ["role": "user", "content": payload]
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw NutritionGroqError.message("No valid response from Groq. Check your connection.")
        }
        if !(200...299).contains(http.statusCode) {
            let envelope = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
            let apiError = (envelope?["error"] as? [String: Any])?["message"] as? String
            let generic: String
            switch http.statusCode {
            case 401, 403: generic = "The Groq API key was rejected. Check or replace it."
            case 429: generic = "Groq is rate-limiting requests. Try again later."
            default: generic = "Groq returned HTTP \(http.statusCode)."
            }
            throw NutritionGroqError.message(apiError ?? generic)
        }
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = object["choices"] as? [[String: Any]],
              let first = choices.first,
              let answer = (first["message"] as? [String: Any])?["content"] as? String,
              !answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw NutritionGroqError.message("Groq did not return a readable summary. Please try again.")
        }
        return answer
    }

    // Use Groq's strict structured outputs; the caller still validates every value.
    static func estimate(_ payload: String, key: String) async throws -> NutritionGroqEstimateResponse {
        guard let url = URL(string: "https://api.groq.com/openai/v1/chat/completions") else {
            throw NutritionGroqError.message("Groq API address is invalid.")
        }
        let numberOrNull: [String: Any] = ["type": ["number", "null"]]
        let properties: [String: Any] = [
            "mealID": ["type": "string"],
            "ingredientIndex": ["type": "integer"],
            "proteinG": numberOrNull, "fibreG": numberOrNull,
            "carbohydrateG": numberOrNull, "ironMg": numberOrNull,
            "magnesiumMg": numberOrNull, "b12Micrograms": numberOrNull,
            "confidence": ["type": "string", "enum": ["low", "moderate"]],
            "note": ["type": "string"]
        ]
        let ingredientSchema: [String: Any] = [
            "type": "object", "additionalProperties": false,
            "properties": properties,
            "required": ["mealID", "ingredientIndex", "proteinG", "fibreG",
                         "carbohydrateG", "ironMg", "magnesiumMg", "b12Micrograms",
                         "confidence", "note"]
        ]
        let schema: [String: Any] = [
            "type": "object", "additionalProperties": false,
            "properties": ["ingredients": ["type": "array", "items": ingredientSchema]],
            "required": ["ingredients"]
        ]
        let system = """
        Return strict JSON only. The input lists specific eaten portions and MISSING nutrient keys.
        Provide approximate contributions for the consumed portion (NOT per 100 grams).
        proteinG, fibreG, carbohydrateG are in grams. ironMg and magnesiumMg are in milligrams.
        b12Micrograms is in micrograms. Never provide calories.
        Copy each mealID and ingredientIndex EXACTLY. Only fill fields listed as MISSING;
        set all other nutrient fields to null. Known reported zero is not missing.
        If uncertain about a nutrient or an ingredient's identity, set that field null, NOT zero.
        Do not invent fortification, specific branded composition, unknown ingredients or preparation.
        If the brand of milk or a substitute isn't clear, do not invent B12 fortification.
        These are rough, model-generated estimates, not source-verified values.
        Use modest rounded numbers, no misleading precision; note important food assumptions.
        Return confidence as 'low' or 'moderate'. This isn't a clinical dietary assessment.
        """
        let body: [String: Any] = [
            "model": "openai/gpt-oss-120b",
            "reasoning_effort": "low",
            "include_reasoning": false,
            "temperature": 0.2,
            "max_completion_tokens": 2400,
            "response_format": [
                "type": "json_schema",
                "json_schema": ["name": "food_diary_estimates_v1", "strict": true, "schema": schema]
            ],
            "messages": [
                ["role": "system", "content": system],
                ["role": "user", "content": payload]
            ]
        ]
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 45
        request.setValue("Bearer " + key, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw NutritionGroqError.message("No response from Groq.")
        }
        guard (200...299).contains(http.statusCode) else {
            let errorJSON = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
            let apiError = (errorJSON?["error"] as? [String: Any])?["message"] as? String
            throw NutritionGroqError.message(apiError ?? "Groq returned HTTP \(http.statusCode).")
        }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let content = (choices.first?["message"] as? [String: Any])?["content"] as? String,
              let resultData = content.data(using: .utf8),
              let parsed = try? JSONDecoder().decode(NutritionGroqEstimateResponse.self, from: resultData) else {
            throw NutritionGroqError.message("Groq's structured estimates could not be read. Try again.")
        }
        return parsed
    }
}

struct NutritionGroqReviewView: View {
    let payload: String
    var estimatePayload: String = ""
    var onApplyEstimates: (([NutritionGroqIngredientEstimate]) -> Int)? = nil
    @Environment(\.dismiss) private var dismiss
    @State private var hasKey = false
    @State private var newKey = ""
    @State private var showingKeyEditor = false
    @State private var working = false
    @State private var resultText = ""
    @State private var estimates: NutritionGroqEstimateResponse? = nil
    @State private var applied = false
    @State private var appliedCount = 0
    @State private var feedback: String? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Label("Your nutrition, in context", systemImage: "sparkles")
                        .font(.title2.weight(.semibold))
                    Text("Groq will review your logged foods and portions, cautiously estimate nutrients missing from product labels, and suggest ways to round out the day using your kitchen. Estimates are clearly labelled.")
                        .foregroundStyle(.secondary)

                    if !hasKey || showingKeyEditor {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Connect your personal Groq API key")
                                .font(.headline)
                            SecureField("Paste gsk_… API key", text: $newKey)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .textContentType(.password)
                                .padding(10)
                                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
                            Button("Save key on this iPhone") {
                                if NutritionGroqKeychain.save(newKey) {
                                    newKey = ""
                                    hasKey = true
                                    showingKeyEditor = false
                                    feedback = nil
                                } else {
                                    feedback = "That doesn't look like a Groq API key, or it couldn't be saved securely."
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            Text("Get a key at console.groq.com/keys. It's saved in iPhone Keychain, not in your code or GitHub.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Button("Change or remove Groq key") {
                            showingKeyEditor = true
                        }
                        .font(.caption)
                        .buttonStyle(.borderless)
                        Button("Remove saved key", role: .destructive) {
                            NutritionGroqKeychain.remove()
                            hasKey = false
                            newKey = ""
                            showingKeyEditor = false
                            resultText = ""
                        }
                        .font(.caption)
                    }

                    Divider()
                    Text("Privacy: day details are sent to Groq only when you tap a Groq button. Your checked kitchen items are only sent for the written review. No calories are shared.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button {
                        Task { await analyse() }
                    } label: {
                        HStack {
                            if working { ProgressView().tint(.white) }
                            Label(working ? "Analysing…" : "Summarise with Groq", systemImage: "sparkles")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(red: 0.11, green: 0.48, blue: 0.40))
                    .disabled(!hasKey || working)

                    if !estimatePayload.isEmpty && onApplyEstimates != nil {
                        Button {
                            Task { await calculateEstimates() }
                        } label: {
                            HStack {
                                if working { ProgressView().tint(.white) }
                                Label(working ? "Estimating…" : "Estimate missing nutrients", systemImage: "chart.bar.xaxis")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 7)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!hasKey || working)
                        Text("Estimates are calculated only for missing fields with a known portion. You choose whether to apply them.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let estimates {
                        Text("Proposed AI estimates").font(.headline)
                        ForEach(estimates.ingredients.filter { $0.hasNumbers }) { item in
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Ingredient \(item.ingredientIndex + 1) · \(item.confidence) confidence")
                                    .font(.subheadline.weight(.semibold))
                                Text(estimateSummary(item))
                                    .font(.caption)
                                if !item.note.isEmpty {
                                    Text(item.note).font(.caption2).foregroundStyle(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        if estimates.ingredients.contains(where: { $0.hasNumbers }) && !applied {
                            Button("Apply estimates to diary stats") {
                                let count = onApplyEstimates?(estimates.ingredients) ?? 0
                                if count > 0 {
                                    applied = true
                                    appliedCount = count
                                    feedback = nil
                                } else {
                                    feedback = "No estimates were applied. The meals may have changed or the values could not be verified."
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        Text("These are rough AI guesses, not tested nutrition facts. Recorded label data always takes precedence, and unestimated fields remain unknown.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    if appliedCount > 0 {
                        Text("Saved \(appliedCount) ingredient estimates. Recorded and approximate values are now separated in your daily stats.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    if let feedback {
                        Text(feedback)
                            .foregroundStyle(.red)
                            .font(.subheadline)
                            .textSelection(.enabled)
                    }
                    if !resultText.isEmpty {
                        Text("Nutrition review and estimates").font(.headline)
                        Text(.init(resultText))
                            .textSelection(.enabled)
                        Text("Approximate nutrients are AI estimates, not product measurements. Use them to guide meal ideas, not to diagnose a deficiency. Diary data may be incomplete.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(20)
            }
            .navigationTitle("Groq Nutrition")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear { hasKey = NutritionGroqKeychain.read() != nil }
        }
    }

    private func estimateSummary(_ item: NutritionGroqIngredientEstimate) -> String {
        let values: [(String, String, Double?)] = [
            ("protein", "g", item.proteinG), ("fibre", "g", item.fibreG),
            ("carbs", "g", item.carbohydrateG), ("iron", "mg", item.ironMg),
            ("magnesium", "mg", item.magnesiumMg), ("B12", "µg", item.b12Micrograms)
        ]
        return values.compactMap { label, unit, number in
            guard let number, number.isFinite, number >= 0 else { return nil }
            return "\(label) ≈\(String(format: "%.2g", number)) \(unit)"
        }.joined(separator: " · ")
    }

    @MainActor
    private func calculateEstimates() async {
        guard let key = NutritionGroqKeychain.read() else {
            hasKey = false
            feedback = "Add your personal Groq key first."
            return
        }
        working = true
        feedback = nil
        estimates = nil
        applied = false
        appliedCount = 0
        defer { working = false }
        do {
            let response = try await NutritionGroqService.estimate(estimatePayload, key: key)
            estimates = response
            if !response.ingredients.contains(where: { $0.hasNumbers }) {
                feedback = "Groq couldn't make dependable numeric estimates for these portions. Your recorded stats are unchanged."
            }
        } catch {
            feedback = error.localizedDescription
        }
    }

    @MainActor
    private func analyse() async {
        guard let key = NutritionGroqKeychain.read() else {
            hasKey = false
            feedback = "Add your personal Groq key first."
            return
        }
        working = true
        feedback = nil
        resultText = ""
        defer { working = false }
        do {
            resultText = try await NutritionGroqService.review(payload, key: key)
        } catch {
            feedback = error.localizedDescription
        }
    }
}
