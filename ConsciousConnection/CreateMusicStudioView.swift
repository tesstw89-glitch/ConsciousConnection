import SwiftUI

struct MusicChord: Codable, Hashable {
    let symbol: String
    let bars: Int
    let notes: [String]
}

struct MusicLab: Codable, Identifiable {
    let id: String
    let instrument: String
    let number: Int
    let category: String
    let title: String
    let subtitle: String
    let tonal: String
    let progression: String
    let groove: String
    let goal: String
    let palette: String
    let saxChords: String
    let backing: String
    let steps: [String]
    let bringHome: String
    let chords: [MusicChord]
}

private struct MusicLabFile: Codable {
    let schema: Int
    let source: String
    let labs: [MusicLab]
}

enum MusicLabLibrary {
    static let all: [MusicLab] = {
        guard let url = Bundle.main.url(forResource: "MusicLabCatalog", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(MusicLabFile.self, from: data) else {
            return []
        }
        return file.labs
    }()
}

private let studioMint = Color(red: 0.61, green: 0.92, blue: 0.80)
private let studioInk = Color(red: 0.07, green: 0.10, blue: 0.14)

struct CreateMusicHomeView: View {
    var body: some View {
        StudioBackground {
            VStack(alignment: .leading, spacing: 16) {
                Text("CREATE / RYE DAZE")
                    .font(.caption.bold()).tracking(2).foregroundStyle(studioMint)
                Text("Make music.")
                    .font(.largeTitle.bold()).foregroundStyle(.white)
                Text("Pick something you actually want to practise. Your instrument, your songs, your musical ideas.")
                    .foregroundStyle(.white.opacity(0.72)).padding(.bottom, 6)
                StudioLink(title: "Practice an instrument",
                           subtitle: "22 saxophone labs · 19 Minilogue chord labs",
                           icon: "music.mic", destination: MusicInstrumentPickerView())
                StudioLink(title: "Quick Create",
                           subtitle: "Make a musical idea, not a perfect loop",
                           icon: "waveform.path", destination: QuickCreateIdeasView())
                StudioLink(title: "Song arrangement laboratory",
                           subtitle: "Entrances, exits, textures and transitions",
                           icon: "square.stack.3d.up", destination: CreateSongLabView())
                StudioLink(title: "Work on an existing song",
                           subtitle: "Continue a song plan you've already started",
                           icon: "slider.horizontal.3", destination: CreateSongLabView())
                StudioLink(title: "Practise an existing song",
                           subtitle: "A deliberate performance rehearsal",
                           icon: "metronome", destination: PractiseExistingSongView())
                Text("Music first. The studio backings are production briefs; no audio is bundled in this version.")
                    .font(.footnote).foregroundStyle(.white.opacity(0.59)).padding(.top, 10)
            }
            .padding(.horizontal, 22).padding(.top, 28).padding(.bottom, 42)
        }
        .navigationTitle("Create")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct StudioBackground<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        ZStack {
            LinearGradient(colors: [studioInk, Color(red: 0.14, green: 0.19, blue: 0.23), studioInk],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            ScrollView { content }
        }
    }
}

private struct StudioLink<Destination: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    let destination: Destination
    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 15) {
                Image(systemName: icon).font(.title2).foregroundStyle(studioMint).frame(width: 36)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.headline).foregroundStyle(.white)
                    Text(subtitle).font(.caption).foregroundStyle(.white.opacity(0.64))
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right").foregroundStyle(.white.opacity(0.6))
            }
            .padding(17).background(.white.opacity(0.085), in: RoundedRectangle(cornerRadius: 17))
        }
        .buttonStyle(.plain)
    }
}

struct MusicInstrumentPickerView: View {
    var body: some View {
        StudioBackground {
            VStack(alignment: .leading, spacing: 16) {
                Text("PRACTICE AN INSTRUMENT")
                    .font(.caption.bold()).tracking(1.6).foregroundStyle(studioMint)
                Text("Choose your studio").font(.largeTitle.bold()).foregroundStyle(.white)
                StudioLink(title: "Saxophone Studio",
                           subtitle: "22 full-band improvisation labs · written E♭ alto notes",
                           icon: "music.note", destination: MusicLabListView(instrument: "sax"))
                StudioLink(title: "Keys Studio",
                           subtitle: "19 harmony labs · coloured Minilogue chord diagrams",
                           icon: "pianokeys", destination: MusicLabListView(instrument: "keys"))
            }.padding(22)
        }
        .navigationTitle("Practice an instrument")
    }
}

struct MusicLabListView: View {
    let instrument: String
    @State private var search = ""
    private var labs: [MusicLab] {
        MusicLabLibrary.all.filter {
            $0.instrument == instrument &&
            (search.isEmpty || $0.title.localizedStandardContains(search)
             || $0.tonal.localizedStandardContains(search)
             || $0.category.localizedStandardContains(search))
        }
    }
    var body: some View {
        StudioBackground {
            VStack(alignment: .leading, spacing: 14) {
                Text(instrument == "keys" ? "KEYS / MINILOGUE MIDI" : "SAXOPHONE / E♭ ALTO")
                    .font(.caption.bold()).tracking(1.5).foregroundStyle(studioMint)
                Text(instrument == "keys" ? "Harmony to play." : "Improvise with the band.")
                    .font(.title.bold()).foregroundStyle(.white)
                Text(instrument == "keys" ?
                     "Concert-pitch chords. Drum and bass accompaniment only." :
                     "Backing chords are concert pitch. Your sax notes are written for E♭ alto.")
                    .font(.subheadline).foregroundStyle(.white.opacity(0.7))
                TextField("Find a sound, key or lesson", text: $search)
                    .textInputAutocapitalization(.never)
                    .padding(13).background(.white.opacity(0.11), in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.white)
                ForEach(labs) { lab in
                    NavigationLink(destination: MusicLabDetailView(lab: lab)) {
                        HStack(alignment: .top, spacing: 14) {
                            Text(String(format: "%02d", lab.number))
                                .font(.system(.title3, design: .rounded, weight: .bold))
                                .foregroundStyle(studioMint).frame(width: 39)
                            VStack(alignment: .leading, spacing: 5) {
                                Text(lab.title).font(.headline).foregroundStyle(.white)
                                Text(lab.category.capitalized).font(.caption2.bold()).foregroundStyle(studioMint)
                                Text(lab.tonal).font(.caption).foregroundStyle(.white.opacity(0.68))
                            }
                            Spacer()
                            Image(systemName: "chevron.right").foregroundStyle(.white.opacity(0.45))
                        }
                        .padding(15).background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 15))
                    }.buttonStyle(.plain)
                }
                if labs.isEmpty { Text("No matching lessons.").foregroundStyle(.white.opacity(0.7)) }
            }.padding(20).padding(.bottom, 30)
        }
        .navigationTitle(instrument == "keys" ? "Keys Studio" : "Saxophone Studio")
    }
}

struct MusicLabDetailView: View {
    let lab: MusicLab
    @State private var chordIndex = 0
    @State private var rootless = false
    @State private var inversion = 0
    @State private var notes = ""
    @State private var lastPractised: Date?
    private var currentChord: MusicChord? {
        guard !lab.chords.isEmpty else { return nil }
        return lab.chords[min(chordIndex, lab.chords.count - 1)]
    }
    private var practiceDateKey: String { "MusicStudio.Practised." + lab.id }
    private var notesKey: String { "MusicStudio.Notes." + lab.id }
    var body: some View {
        StudioBackground {
            VStack(alignment: .leading, spacing: 16) {
                Text("\(lab.instrument == "keys" ? "KEYS" : "SAX") · LAB \(String(format: "%02d", lab.number))")
                    .font(.caption.bold()).tracking(1.6).foregroundStyle(studioMint)
                Text(lab.title).font(.largeTitle.bold()).foregroundStyle(.white)
                Text(lab.category.capitalized + " · " + lab.tonal)
                    .font(.subheadline).foregroundStyle(studioMint)
                Text(lab.goal).font(.body).foregroundStyle(.white.opacity(0.86))
                infoBlock("THE MUSICAL WORLD", lab.groove + "\n" + lab.progression)
                if lab.instrument == "keys" {
                    if let chord = currentChord { chordPanel(chord) }
                    infoBlock("HARMONIC INGREDIENTS", lab.palette)
                } else {
                    infoBlock("ALTO WRITTEN", lab.saxChords + "\n" + lab.palette)
                }
                infoBlock(lab.instrument == "keys" ? "DRUMS + BASS ARRANGEMENT" : "FULL-BAND ARRANGEMENT",
                          lab.backing)
                Text("YOUR PRACTICE").font(.caption.bold()).tracking(1.5).foregroundStyle(studioMint)
                ForEach(Array(lab.steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 12) {
                        Text(String(format: "%02d", index + 1))
                            .font(.caption.bold()).foregroundStyle(studioMint).frame(width: 26)
                        Text(step).font(.subheadline).foregroundStyle(.white.opacity(0.91))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(13).frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
                }
                infoBlock("BRING HOME", lab.bringHome)
                VStack(alignment: .leading, spacing: 12) {
                    Text("PRACTICE NOTES").font(.caption.bold()).tracking(1.5).foregroundStyle(studioMint)
                    TextField("Something you discovered or want to revisit", text: $notes, axis: .vertical)
                        .lineLimit(3...6).padding(12)
                        .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(.white)
                        .onChange(of: notes) { _, value in
                            UserDefaults.standard.set(value, forKey: notesKey)
                        }
                    Button {
                        let now = Date()
                        UserDefaults.standard.set(now, forKey: practiceDateKey)
                        lastPractised = now
                    } label: {
                        Label(lastPractised == nil ? "Mark practised" :
                                "Practised · \(lastPractised!.formatted(date: .abbreviated, time: .omitted))",
                              systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity).padding(15)
                            .background(studioMint, in: RoundedRectangle(cornerRadius: 14))
                            .foregroundStyle(studioInk)
                    }.buttonStyle(.plain)
                }
            }.padding(20).padding(.bottom, 35)
        }
        .navigationTitle("Lab \(lab.number)").navigationBarTitleDisplayMode(.inline)
        .onAppear {
            notes = UserDefaults.standard.string(forKey: notesKey) ?? ""
            lastPractised = UserDefaults.standard.object(forKey: practiceDateKey) as? Date
        }
    }
    private func infoBlock(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.caption.bold()).tracking(1.4).foregroundStyle(studioMint)
            Text(body).font(.subheadline).foregroundStyle(.white.opacity(0.86))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 15))
    }
    private func chordPanel(_ chord: MusicChord) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("MINILOGUE · CHORD SHAPE")
                        .font(.caption2.bold()).tracking(1.1).foregroundStyle(studioMint)
                    Text(chord.symbol).font(.title2.bold()).foregroundStyle(.white)
                    if chord.bars > 0 {
                        Text("\(chord.bars) bars").font(.caption).foregroundStyle(.white.opacity(0.65))
                    }
                }
                Spacer()
                Button {
                    chordIndex = (chordIndex + lab.chords.count - 1) % lab.chords.count
                    inversion = 0
                } label: { Image(systemName: "chevron.left").padding(10) }
                    .accessibilityLabel("Previous chord")
                Button {
                    chordIndex = (chordIndex + 1) % lab.chords.count
                    inversion = 0
                } label: { Image(systemName: "chevron.right").padding(10) }
                    .accessibilityLabel("Next chord")
            }.foregroundStyle(studioMint)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 7) {
                    ForEach(lab.chords.indices, id: \.self) { index in
                        Button {
                            chordIndex = index
                            inversion = 0
                        } label: {
                            Text(lab.chords[index].symbol).font(.caption.bold())
                                .padding(.horizontal, 10).padding(.vertical, 8)
                                .background(index == chordIndex ? studioMint : Color.white.opacity(0.1),
                                            in: Capsule())
                                .foregroundStyle(index == chordIndex ? studioInk : Color.white)
                        }.buttonStyle(.plain)
                    }
                }
            }
            MinilogueChordDiagram(chord: chord, rootless: rootless, inversion: inversion)
            HStack(spacing: 9) {
                Toggle("Rootless", isOn: $rootless).toggleStyle(.switch).tint(studioMint)
                Spacer()
                Button("Next inversion") { inversion += 1 }
                    .font(.caption.bold()).foregroundStyle(studioMint)
            }
            Text("PLAY: " + ChordVoicing.positions(for: chord, rootless: rootless, inversion: inversion)
                .map(\.label).joined(separator: " · "))
                .font(.caption.monospaced()).foregroundStyle(.white.opacity(0.82))
            HStack(spacing: 12) {
                Circle().fill(Color(red: 1.00, green: 0.72, blue: 0.39)).frame(width: 9, height: 9)
                Text("Root").font(.caption)
                Circle().fill(Color(red: 0.30, green: 0.84, blue: 0.73)).frame(width: 9, height: 9)
                Text("Other notes").font(.caption)
                Spacer()
            }.foregroundStyle(.white.opacity(0.75))
            Text("Suggested playable voicing. The slash note belongs to the backing bass. Try inversions and rootless grips. Use Minilogue as a MIDI controller for Ableton.")
                .font(.caption2).foregroundStyle(.white.opacity(0.62))
        }.padding(16).background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))
    }
}

struct QuickCreateIdeasView: View {
    @State private var idea = 0
    private let ideas: [(String, String)] = [
        ("Rhythm first", "Make an eight-bar drum groove. Add bass only when the beat has its own personality. Finish with a simple chord or melody."),
        ("Harmony first", "Find a chord colour that moves you. Add bass and a contrasting drum rhythm. Save one complete musical idea."),
        ("Texture first", "Make a strange rhythmic texture with XO samples. Add a harmonic layer, then let the texture support a short groove."),
        ("Bass first", "Play a bass figure on any controller. Make your drums answer it. Add one melodic or chordal idea."),
        ("Unexpected turn", "Build a short groove. Change just one part halfway through so it briefly becomes another musical world.")
    ]
    var body: some View {
        StudioBackground {
            VStack(alignment: .leading, spacing: 18) {
                Text("QUICK CREATE").font(.caption.bold()).tracking(1.5).foregroundStyle(studioMint)
                Text("Make something small.").font(.largeTitle.bold()).foregroundStyle(.white)
                Text(ideas[idea].0).font(.title2.bold()).foregroundStyle(studioMint)
                Text(ideas[idea].1).foregroundStyle(.white.opacity(0.85)).padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 15))
                Button { idea = (idea + 1) % ideas.count } label: {
                    Label("Another challenge", systemImage: "shuffle")
                        .padding(13).frame(maxWidth: .infinity)
                }.buttonStyle(.borderedProminent).tint(studioMint)
                Text("You choose all the actual notes, sounds, instruments and tempo.")
                    .font(.footnote).foregroundStyle(.white.opacity(0.6))
            }.padding(22)
        }
        .navigationTitle("Quick Create")
    }
}

struct PractiseExistingSongView: View {
    @AppStorage("MusicPracticeSong.title.v1") private var title = ""
    @AppStorage("MusicPracticeSong.focus.v1") private var focus = ""
    @AppStorage("MusicPracticeSong.notes.v1") private var notes = ""
    var body: some View {
        StudioBackground {
            VStack(alignment: .leading, spacing: 15) {
                Text("PRACTISE AN EXISTING SONG")
                    .font(.caption.bold()).tracking(1.4).foregroundStyle(studioMint)
                Text("Get it under your fingers.").font(.title.bold()).foregroundStyle(.white)
                Text("Choose one passage of a song you're learning or performing. Make one useful improvement rather than trying to perfect everything at once.")
                    .foregroundStyle(.white.opacity(0.8))
                input("SONG", text: $title, prompt: "What are you playing?")
                input("TODAY'S FOCUS", text: $focus, prompt: "A transition, solo, chord section, or full run-through")
                input("NEXT TIME", text: $notes, prompt: "What should you revisit?")
            }.padding(22)
        }
        .navigationTitle("Practise a song")
    }
    private func input(_ heading: String, text: Binding<String>, prompt: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(heading).font(.caption.bold()).foregroundStyle(studioMint)
            TextField(prompt, text: text, axis: .vertical)
                .lineLimit(2...4).padding(12)
                .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(.white)
        }
    }
}