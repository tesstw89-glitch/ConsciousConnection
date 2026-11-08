//
//  WorkoutHistorySectionView.swift
//  SetDeck
//
//  Created by Nick Molargik on 11/29/25.
//

import SwiftUI

struct WorkoutHistorySectionView: View {
    @Environment(HealthManager.self) private var healthManager: HealthManager
    @State private var isExpanded: Bool = true
    @AppStorage(StrengthLabCompletedSessions.storageKey) private var sessionData: Data = Data()

    private var strengthLabSessions: [StrengthLabCompletedSession] {
        (try? JSONDecoder().decode([StrengthLabCompletedSession].self, from: sessionData))?
            .sorted { $0.endedAt > $1.endedAt } ?? []
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            DisclosureGroup(isExpanded: $isExpanded) {
                let workouts = healthManager.workoutHistory
                let sessions = strengthLabSessions
                VStack(alignment: .leading, spacing: 12) {
                    if !sessions.isEmpty {
                        Text("StrengthLab sessions")
                            .font(.subheadline.bold())
                            .foregroundStyle(.primary)
                        ForEach(sessions) { session in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "dumbbell.fill")
                                    .foregroundStyle(.pink)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(session.workoutName)
                                        .font(.subheadline.bold())
                                    Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text("\(session.completedSetCount) sets · \(Int(session.endedAt.timeIntervalSince(session.startedAt) / 60)) min" + (session.endedEarly ? " · Ended early" : ""))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                            .padding(12)
                            .background(Color.pink.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    if !workouts.isEmpty {
                        Text("Apple Health workouts")
                            .font(.subheadline.bold())
                            .foregroundStyle(.primary)
                        ForEach(workouts, id: \.id) { workout in
                            WorkoutRowView(
                                title: workout.title,
                                subtitle: workout.subtitle,
                                durationString: workout.durationString,
                                systemImageName: systemIconForWorkout(title: workout.title, subtitle: workout.subtitle)
                            )
                            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: workout.id)
                        }
                    } else if sessions.isEmpty {
                        ContentUnavailableView("No Workouts", systemImage: "figure.run", description: Text("Completed StrengthLab sessions and Apple Health workouts will appear here."))
                    }
                }
                .padding(.top, 8)
            } label: {
                Text("Workout History").font(.title2.bold())
            }
            .foregroundStyle(Color.greenStart)
        }
    }

    private func systemIconForWorkout(title: String, subtitle: String) -> String {
        let t = (title + " " + subtitle).lowercased()
        if t.contains("run") || t.contains("jog") { return "figure.run" }
        if t.contains("walk") || t.contains("hike") { return "figure.walk" }
        if t.contains("cycle") || t.contains("bike") { return "bicycle" }
        if t.contains("swim") { return "figure.pool.swim" }
        if t.contains("row") { return "figure.rower" }
        if t.contains("yoga") || t.contains("stretch") { return "figure.yoga" }
        if t.contains("strength") || t.contains("weights") || t.contains("lift") { return "figure.strengthtraining.traditional" }
        if t.contains("hiit") || t.contains("interval") { return "flame.fill" }
        if t.contains("pilates") { return "figure.mind.and.body" }
        if t.contains("stair") { return "figure.stairs" }
        if t.contains("ski") { return "figure.skiing.downhill" }
        if t.contains("elliptical") { return "figure.elliptical" }
        if t.contains("dance") { return "figure.dance" }
        return "figure.run"
    }
}
#Preview {
    WorkoutHistorySectionView()
        .padding()
        .environment(HealthManager())
        .preferredColorScheme(.dark)
}

// STRENGTHLAB_NOV03_EMBEDDED_COMPLETED_SESSIONS
struct StrengthLabCompletedSession: Codable, Identifiable {
    var id: UUID = UUID()
    var workoutName: String
    var startedAt: Date
    var endedAt: Date
    var completedSetCount: Int
    var endedEarly: Bool
}

@MainActor
enum StrengthLabCompletedSessions {
    static let storageKey = "strengthlab_completed_sessions_v1"

    static func record(
        workoutName: String,
        startedAt: Date,
        endedAt: Date,
        completedSetCount: Int,
        endedEarly: Bool
    ) {
        guard completedSetCount > 0 else { return }
        let current = UserDefaults.standard.data(forKey: storageKey)
        var sessions = current.flatMap {
            try? JSONDecoder().decode([StrengthLabCompletedSession].self, from: $0)
        } ?? []
        // No day-based grouping: every session receives a unique ID.
        sessions.insert(
            StrengthLabCompletedSession(
                workoutName: workoutName,
                startedAt: startedAt,
                endedAt: endedAt,
                completedSetCount: completedSetCount,
                endedEarly: endedEarly
            ),
            at: 0
        )
        if let data = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
