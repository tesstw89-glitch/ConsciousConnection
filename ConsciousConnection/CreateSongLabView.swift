import SwiftUI

// MARK: - The Create space
// A song-first arrangement laboratory: blueprints are starting points, not rules.

private struct ArrangementSection: Identifiable {
    let id: String
    let name: String
    let firstBar: Int
    let lastBar: Int
    let music: String
    let drums: String
    let transition: String

    var barCount: Int { lastBar - firstBar + 1 }
    var barLabel: String { "\(firstBar)–\(lastBar)" }
}

private struct ArrangementBlueprint: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let inspiration: String
    let sections: [ArrangementSection]

    var totalBars: Int { sections.reduce(0) { $0 + $1.barCount } }
}

private enum ArrangementLibrary {
    static let all: [ArrangementBlueprint] = [
        ArrangementBlueprint(
            id: "loop",
            title: "Loop → Song",
            subtitle: "One great loop, five distinct states",
            inspiration: "A gentle first step from an 8-bar idea to a complete piece.",
            sections: [
                .init(id: "intro", name: "Intro", firstBar: 1, lastBar: 8,
                      music: "Filtered chords; tease one texture or fragment of the hook.",
                      drums: "Keep just a shaker, rim, or a few ghost hits.",
                      transition: "Open the filter and let the full kick arrive on bar 9."),
                .init(id: "groove", name: "A · Main groove", firstBar: 9, lastBar: 24,
                      music: "Bass, chords and hook together: the identity of the track.",
                      drums: "Use your original XO/MIDI groove; make a small fill in bar 24.",
                      transition: "Add one new sound or rhythmic answer in the final two bars."),
                .init(id: "development", name: "A · Development", firstBar: 25, lastBar: 32,
                      music: "Add a countermelody, chord inversion, or evolving FX layer.",
                      drums: "Make a busier sibling of the main pattern, not a new beat.",
                      transition: "Take away the kick or harmony at the end of bar 32."),
                .init(id: "contrast", name: "B · Contrast", firstBar: 33, lastBar: 40,
                      music: "Introduce a fresh motif; pull back the chords or change the bass.",
                      drums: "Try half-time, sparse percussion, or a changed accent.",
                      transition: "Preview the original hook, then use a short silence."),
                .init(id: "return", name: "Return / ending", firstBar: 41, lastBar: 48,
                      music: "Bring back A with one element borrowed from B; finish deliberately.",
                      drums: "Restore the main groove and choose a final fill or clean stop.",
                      transition: "End with a held chord, hard cut, or a short tail.")
            ]
        ),
        ArrangementBlueprint(
            id: "glitch",
            title: "Glitch Collage",
            subtitle: "Abrupt edits, rhythmic mutations, surprises",
            inspiration: "For Flying Lotus-inspired, deliberately unpredictable pieces.",
            sections: [
                .init(id: "fragment", name: "Hook fragment", firstBar: 1, lastBar: 4,
                      music: "Drop into the middle of a warped chord or chopped melodic idea.",
                      drums: "Only offbeat hats and odd FX hits.",
                      transition: "Hard-cut to the beat; skip the traditional riser."),
                .init(id: "beat", name: "Beat arrives", firstBar: 5, lastBar: 12,
                      music: "Reveal bass and the complete sample phrase.",
                      drums: "Establish a swung, off-centre pocket.",
                      transition: "Repeat a tiny melodic fragment as a rhythmic cue."),
                .init(id: "mutation", name: "Mutation", firstBar: 13, lastBar: 20,
                      music: "Resample and pitch-shift the hook; swap texture palettes.",
                      drums: "Keep the groove DNA but displace an accent or omit the snare.",
                      transition: "Stutter the last half bar, then make a sudden cut."),
                .init(id: "interlude", name: "Unexpected interlude", firstBar: 21, lastBar: 28,
                      music: "A new harmonic colour: field recording, sax, or reversed Rhodes.",
                      drums: "Almost no kick; sparse fragments and room noise.",
                      transition: "Let a new bass note foreshadow the next pocket."),
                .init(id: "pocket", name: "New pocket", firstBar: 29, lastBar: 40,
                      music: "A related but noticeably different groove or chord loop.",
                      drums: "Reprogramme the hats and kick; preserve one recognisable motif.",
                      transition: "Bring back one sound from the opening in bars 39–40."),
                .init(id: "collision", name: "Collision / exit", firstBar: 41, lastBar: 48,
                      music: "Layer the first hook over the new pocket; strip it down to a stop.",
                      drums: "Momentary double-time fill, then a sudden removal.",
                      transition: "Finish with an unresolved texture or a clean punch-out.")
            ]
        ),
        ArrangementBlueprint(
            id: "slowburn",
            title: "Slow-Burn Build",
            subtitle: "Hypnosis, evolving details, a satisfying release",
            inspiration: "For psychedelic, atmospheric and repetition-led music.",
            sections: [
                .init(id: "seed", name: "Seeds", firstBar: 1, lastBar: 8,
                      music: "One motif, lots of air; automate space and filtering.",
                      drums: "Only quiet percussion or noise.",
                      transition: "Introduce a repeating pulse."),
                .init(id: "pulse", name: "Pulse", firstBar: 9, lastBar: 16,
                      music: "Bass enters; a chord or melodic fragment stays deliberately small.",
                      drums: "Simple kick and hat foundation.",
                      transition: "A subtle pickup leads into the full groove."),
                .init(id: "lift", name: "First lift", firstBar: 17, lastBar: 32,
                      music: "Reveal the whole motif; slowly add harmonies or countermelodies.",
                      drums: "Add ghost notes and a second percussion layer over 16 bars.",
                      transition: "Peel away the bass during bars 31–32."),
                .init(id: "break", name: "Breakdown", firstBar: 33, lastBar: 40,
                      music: "Leave the chords and one strange texture exposed.",
                      drums: "No kick; sparse clicks or a washed-out snare.",
                      transition: "Build tension through rhythm and automation, not just a riser."),
                .init(id: "peak", name: "Final build", firstBar: 41, lastBar: 56,
                      music: "The fullest version of the original motif, with one fresh layer.",
                      drums: "Main groove returns; hats and fills grow more animated.",
                      transition: "Start removing layers in bars 55–56."),
                .init(id: "release", name: "Release", firstBar: 57, lastBar: 64,
                      music: "Land on the simplest form of the original idea.",
                      drums: "Thin the groove to a pulse or let the beat disappear.",
                      transition: "End with a graceful fade, tail, or last chord.")
            ]
        ),
        ArrangementBlueprint(
            id: "live",
            title: "Live-Layered",
            subtitle: "Build a performance one instrument at a time",
            inspiration: "A route towards FKJ-style layering and a playable Rye Daze repertoire.",
            sections: [
                .init(id: "motif", name: "Solo motif", firstBar: 1, lastBar: 8,
                      music: "Begin with a playable sax, keys, guitar, or bass phrase.",
                      drums: "None yet; leave room for the performance.",
                      transition: "Bring in a simple timekeeping layer."),
                .init(id: "bed", name: "Rhythm bed", firstBar: 9, lastBar: 16,
                      music: "Loop the motif; add a bass foundation or chord pad.",
                      drums: "Finger-drummed percussion or an XO groove.",
                      transition: "Short pickup or drum fill into the full arrangement."),
                .init(id: "main", name: "Full ensemble", firstBar: 17, lastBar: 32,
                      music: "Bass + harmony + lead melody working together.",
                      drums: "Play the recognisable main beat, with a light variation at bar 32.",
                      transition: "Drop out the lead instrument to make space for a feature."),
                .init(id: "feature", name: "Instrument feature", firstBar: 33, lastBar: 48,
                      music: "Sax solo, bass feature, guitar answer, or improvised keys.",
                      drums: "Strip back the first 8 bars; build to a slightly busier variation.",
                      transition: "Repeat a cue from the opening to signal the return."),
                .init(id: "reprise", name: "Reprise", firstBar: 49, lastBar: 56,
                      music: "Bring the opening melody back, now with the full rhythm bed.",
                      drums: "Return to the main pattern rather than continually adding.",
                      transition: "Remove parts one by one for a live-feeling ending."),
                .init(id: "outro", name: "Outro", firstBar: 57, lastBar: 64,
                      music: "End on the original solo instrument or a simple final chord.",
                      drums: "Stop the loop or play a final fill.",
                      transition: "Finish cleanly; leave a little room tone.")
            ]
        ),
        ArrangementBlueprint(
            id: "dance",
            title: "House / Broken Beat",
            subtitle: "A longer groove with a dramatic breakdown",
            inspiration: "For house, broken beat, Afro-inspired rhythms and DJ-friendly flow.",
            sections: [
                .init(id: "djintro", name: "Rhythm intro", firstBar: 1, lastBar: 16,
                      music: "Percussion, texture and tiny hints of the harmony.",
                      drums: "Start stripped; establish the pulse clearly.",
                      transition: "Introduce bass or a hook pickup ahead of bar 17."),
                .init(id: "core", name: "Core groove", firstBar: 17, lastBar: 32,
                      music: "Bring bass, chords and central hook together.",
                      drums: "Full main groove with a small variation near bar 32.",
                      transition: "Add a new percussion answer or chord stab."),
                .init(id: "variation", name: "Groove variation", firstBar: 33, lastBar: 48,
                      music: "Keep the harmony familiar; evolve melody and texture.",
                      drums: "Switch hats, ghost notes or percussion placement.",
                      transition: "Remove kick and bass in the final two bars."),
                .init(id: "break", name: "Breakdown", firstBar: 49, lastBar: 64,
                      music: "Let the chords breathe; introduce a surprise sample or melodic idea.",
                      drums: "Percussion becomes sparse; use a repeating fill as a cue.",
                      transition: "Set up the drop with anticipation or one beat of silence."),
                .init(id: "drop", name: "Return / drop", firstBar: 65, lastBar: 80,
                      music: "Main hook returns with a small harmonic or textural twist.",
                      drums: "Strongest main groove; save extra fills for select moments.",
                      transition: "Remove the lead and bass in stages."),
                .init(id: "djoutro", name: "Rhythm outro", firstBar: 81, lastBar: 96,
                      music: "Leave the percussion and a fading fragment of the hook.",
                      drums: "Reduce layers for a mix-friendly finish.",
                      transition: "End on a clean phrase boundary.")
            ]
        )
    ]
}

private struct SongPlan: Identifiable, Codable, Equatable {
    var id = UUID()
    var blueprintID: String
    var title: String
    var nextStep: String
    var sectionNotes: [String: String] = [:]
    var completedSectionIDs: Set<String> = []
    var createdAt = Date()
}

private enum SongPlanStore {
    private static let key = "ConsciousConnection.CreateSongPlans.v1"

    static func load() -> [SongPlan] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let plans = try? JSONDecoder().decode([SongPlan].self, from: data) else {
            return []
        }
        return plans
    }

    static func save(_ plans: [SongPlan]) {
        guard let data = try? JSONEncoder().encode(plans) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}

// MARK: - Blueprint library + projects

struct CreateSongLabView: View {
    @State private var chosenID = "loop"
    @State private var plans = SongPlanStore.load()
    @State private var editingPlan: SongPlan?

    private let ink = Color(red: 0.08, green: 0.11, blue: 0.15)
    private let mint = Color(red: 0.64, green: 0.91, blue: 0.78)

    private var chosen: ArrangementBlueprint {
        ArrangementLibrary.all.first(where: { $0.id == chosenID }) ?? ArrangementLibrary.all[0]
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [ink, Color(red: 0.12, green: 0.17, blue: 0.21), ink],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("CREATE / RYE DAZE", systemImage: "waveform.path")
                            .font(.caption.weight(.bold))
                            .tracking(2)
                            .foregroundStyle(mint)

                        Text("Make the music first.")
                            .font(.largeTitle.bold())
                            .foregroundStyle(.white)

                        Text("Turn a brilliant loop into a song. Pick a shape, change it freely, and let the track tell you what to practise.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.74))
                    }
                    .padding(.top, 28)

                    if !plans.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("YOUR TRACKS")
                                .font(.caption.bold())
                                .tracking(1.5)
                                .foregroundStyle(mint)

                            ForEach(plans) { plan in
                                Button {
                                    editingPlan = plan
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: "music.note.list")
                                            .font(.title3)
                                            .foregroundStyle(mint)
                                            .frame(width: 32)

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(plan.title.isEmpty ? "Untitled track" : plan.title)
                                                .font(.headline)
                                                .foregroundStyle(.white)
                                            Text(plan.nextStep.isEmpty ? "Tap to continue arranging" : plan.nextStep)
                                                .font(.caption)
                                                .foregroundStyle(.white.opacity(0.65))
                                                .lineLimit(2)
                                        }
                                        Spacer(minLength: 6)
                                        Image(systemName: "chevron.right")
                                            .foregroundStyle(.white.opacity(0.6))
                                    }
                                    .padding(14)
                                    .background(.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 15))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("ARRANGEMENT BLUEPRINTS")
                            .font(.caption.bold())
                            .tracking(1.5)
                            .foregroundStyle(mint)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(ArrangementLibrary.all) { blueprint in
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            chosenID = blueprint.id
                                        }
                                    } label: {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text(blueprint.title)
                                                .font(.subheadline.bold())
                                            Text("\(blueprint.totalBars) bars")
                                                .font(.caption)
                                            Spacer(minLength: 0)
                                            Image(systemName: chosenID == blueprint.id ? "checkmark.circle.fill" : "circle")
                                                .font(.headline)
                                        }
                                        .foregroundStyle(chosenID == blueprint.id ? ink : .white)
                                        .padding(13)
                                        .frame(width: 147, height: 112, alignment: .leading)
                                        .background(
                                            chosenID == blueprint.id ? mint : Color.white.opacity(0.10),
                                            in: RoundedRectangle(cornerRadius: 15)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text(chosen.title)
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                        Text(chosen.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(mint)
                        Text(chosen.inspiration)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))

                        GeometryReader { geometry in
                            HStack(spacing: 3) {
                                ForEach(chosen.sections.indices, id: \.self) { index in
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(blueprintColour(index))
                                        .frame(
                                            width: max(2, (geometry.size.width - CGFloat(chosen.sections.count - 1) * 3) * CGFloat(chosen.sections[index].barCount) / CGFloat(chosen.totalBars))
                                        )
                                }
                            }
                        }
                        .frame(height: 18)

                        ForEach(chosen.sections.indices, id: \.self) { index in
                            blueprintSection(chosen.sections[index], number: index + 1)
                        }

                        Button {
                            startSong(with: chosen)
                        } label: {
                            Label("Start a track with this blueprint", systemImage: "plus.circle.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(mint, in: RoundedRectangle(cornerRadius: 16))
                                .foregroundStyle(ink)
                        }
                        .buttonStyle(.plain)

                        Text("No fixed rules. Duplicate your XO MIDI groove, make a sparse version, a busy version and one transition fill. The song determines which one belongs where.")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.65))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 50)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editingPlan) { plan in
            SongPlanEditor(plan: plan, onSave: savePlan)
        }
    }

    private func blueprintSection(_ section: ArrangementSection, number: Int) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Circle()
                    .fill(blueprintColour(number - 1))
                    .frame(width: 10, height: 10)
                Text(section.name)
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Text("BARS \(section.barLabel)")
                    .font(.caption2.monospacedDigit().bold())
                    .foregroundStyle(mint)
            }
            sectionLine("SOUND", section.music)
            sectionLine("DRUMS", section.drums)
            sectionLine("NEXT", section.transition)
        }
        .padding(14)
        .background(.white.opacity(0.075), in: RoundedRectangle(cornerRadius: 15))
    }

    private func sectionLine(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.caption2.bold())
                .tracking(1)
                .foregroundStyle(mint)
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.83))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func startSong(with blueprint: ArrangementBlueprint) {
        let song = SongPlan(
            blueprintID: blueprint.id,
            title: "Untitled track",
            nextStep: "Build the first section from your favourite loop"
        )
        plans.insert(song, at: 0)
        SongPlanStore.save(plans)
        editingPlan = song
    }

    private func savePlan(_ updated: SongPlan) {
        guard let index = plans.firstIndex(where: { $0.id == updated.id }) else { return }
        plans[index] = updated
        SongPlanStore.save(plans)
    }
}

private func blueprintColour(_ index: Int) -> Color {
    let palette: [Color] = [
        Color(red: 0.58, green: 0.83, blue: 0.75),
        Color(red: 0.94, green: 0.70, blue: 0.43),
        Color(red: 0.66, green: 0.67, blue: 0.95),
        Color(red: 0.94, green: 0.59, blue: 0.64),
        Color(red: 0.59, green: 0.77, blue: 0.98),
        Color(red: 0.86, green: 0.75, blue: 0.57)
    ]
    return palette[index % palette.count]
}

// MARK: - Working song page (automatically saved)

private struct SongPlanEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State private var plan: SongPlan
    let onSave: (SongPlan) -> Void

    private var blueprint: ArrangementBlueprint {
        ArrangementLibrary.all.first(where: { $0.id == plan.blueprintID }) ?? ArrangementLibrary.all[0]
    }

    init(plan: SongPlan, onSave: @escaping (SongPlan) -> Void) {
        _plan = State(initialValue: plan)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("YOUR SONG") {
                    TextField("Song title", text: $plan.title)
                    LabeledContent("Blueprint", value: blueprint.title)
                    LabeledContent("Length", value: "\(blueprint.totalBars) bars")
                }

                Section {
                    TextField(
                        "One clear next action",
                        text: $plan.nextStep,
                        axis: .vertical
                    )
                    .lineLimit(2...4)
                } header: {
                    Text("NEXT TIME YOU OPEN ABLETON")
                } footer: {
                    Text("Give yourself a specific, doable next step. This appears on the Create home screen.")
                }

                ForEach(blueprint.sections) { section in
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(section.music)
                                .font(.subheadline)
                            Label(section.drums, systemImage: "waveform")
                                .font(.subheadline)
                            Label(section.transition, systemImage: "arrow.right")
                                .font(.subheadline)

                            Divider()

                            TextField(
                                "Your sounds, MIDI variations or transition idea",
                                text: Binding(
                                    get: { plan.sectionNotes[section.id] ?? "" },
                                    set: { plan.sectionNotes[section.id] = $0 }
                                ),
                                axis: .vertical
                            )
                            .lineLimit(2...5)
                        }

                        Toggle("I've built this section", isOn: Binding(
                            get: { plan.completedSectionIDs.contains(section.id) },
                            set: { completed in
                                if completed {
                                    plan.completedSectionIDs.insert(section.id)
                                } else {
                                    plan.completedSectionIDs.remove(section.id)
                                }
                            }
                        ))
                    } header: {
                        Text("\(section.name) · bars \(section.barLabel)")
                    }
                }
            }
            .navigationTitle(plan.title.isEmpty ? "Untitled track" : plan.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        onSave(plan)
                        dismiss()
                    }
                }
            }
            .onChange(of: plan) { _, updated in
                onSave(updated)
            }
            .onDisappear {
                onSave(plan)
            }
        }
    }
}

#Preview {
    NavigationStack {
        CreateSongLabView()
    }
}
