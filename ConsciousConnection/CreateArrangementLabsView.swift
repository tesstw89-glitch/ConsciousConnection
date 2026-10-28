import SwiftUI

private struct ArrangementSectionLab: Codable {
    let first: Int
    let last: Int
    let instruction: String
}

private struct ArrangementPracticeLab: Codable, Identifiable {
    let id: String
    let number: Int
    let title: String
    let inspiration: String
    let idea: String
    let challenge: String
    let bars: [ArrangementSectionLab]
}

private struct ArrangementPracticeFile: Codable {
    let schema: Int
    let source: String
    let labs: [ArrangementPracticeLab]
}

private enum ArrangementPracticeLibrary {
    static let all: [ArrangementPracticeLab] = {
        guard let url = Bundle.main.url(forResource: "SongArrangementCatalog", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(ArrangementPracticeFile.self, from: data) else {
            return []
        }
        return decoded.labs
    }()
}

private let arrangementMint = Color(red: 0.61, green: 0.92, blue: 0.80)

struct MusicArrangementLabsView: View {
    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.10, blue: 0.14).ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("RYE DAZE / SONG LABORATORY")
                        .font(.caption.bold()).tracking(1.5).foregroundStyle(arrangementMint)
                    Text("Turn the loop into a song.")
                        .font(.largeTitle.bold()).foregroundStyle(.white)
                    Text("You write every note. These blueprints provide parts, entrances, exits, transformations and actual transition challenges.")
                        .font(.subheadline).foregroundStyle(.white.opacity(0.74))
                        .padding(.bottom, 8)
                    ForEach(ArrangementPracticeLibrary.all) { lab in
                        NavigationLink(destination: ArrangementPracticeDetailView(lab: lab)) {
                            HStack(alignment: .top, spacing: 13) {
                                Text(String(format: "%02d", lab.number))
                                    .font(.title3.bold()).foregroundStyle(arrangementMint)
                                    .frame(width: 37)
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(lab.title).font(.headline).foregroundStyle(.white)
                                    Text(lab.idea).font(.caption)
                                        .foregroundStyle(.white.opacity(0.70))
                                        .lineLimit(3)
                                    Text("\(lab.bars.last?.last ?? 0) bars")
                                        .font(.caption2.bold()).foregroundStyle(arrangementMint)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").foregroundStyle(.white.opacity(0.5))
                            }
                            .padding(15)
                            .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
                        }.buttonStyle(.plain)
                    }
                    NavigationLink(destination: CreateSongLabView()) {
                        Label("Your saved song plans and original blueprint library",
                              systemImage: "square.stack")
                            .font(.subheadline.bold()).foregroundStyle(arrangementMint)
                            .padding(14).frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Text("Structure is a suggestion, not a rule. Chords, key, tempo, melodies, gear and finished sound remain yours.")
                        .font(.footnote).foregroundStyle(.white.opacity(0.62))
                }
                .padding(20).padding(.bottom, 40)
            }
        }
        .navigationTitle("Song Arrangements")
    }
}

private struct ArrangementPracticeDetailView: View {
    let lab: ArrangementPracticeLab
    @State private var checked: Set<Int> = []
    @State private var ideas: [String: String] = [:]
    private var doneKey: String { "ArrangementLab.Done." + lab.id }
    private var noteKey: String { "ArrangementLab.Notes." + lab.id }

    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.10, blue: 0.14).ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 17) {
                    Text("ARRANGEMENT \(String(format: "%02d", lab.number))")
                        .font(.caption.bold()).tracking(1.5).foregroundStyle(arrangementMint)
                    Text(lab.title).font(.largeTitle.bold()).foregroundStyle(.white)
                    Text(lab.inspiration).font(.caption).foregroundStyle(arrangementMint)
                    Text(lab.idea).foregroundStyle(.white.opacity(0.84))
                    VStack(alignment: .leading, spacing: 6) {
                        Text("THE CHALLENGE")
                            .font(.caption.bold()).tracking(1.5).foregroundStyle(arrangementMint)
                        Text(lab.challenge).font(.subheadline).foregroundStyle(.white)
                    }
                    .padding(16)
                    .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
                    ForEach(lab.bars.indices, id: \.self) { index in
                        let section = lab.bars[index]
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("BARS \(section.first)–\(section.last)")
                                    .font(.caption.bold()).foregroundStyle(arrangementMint)
                                Spacer()
                                Button {
                                    if !checked.insert(index).inserted { checked.remove(index) }
                                    UserDefaults.standard.set(Array(checked).sorted(), forKey: doneKey)
                                } label: {
                                    Label(checked.contains(index) ? "Built" : "Mark built",
                                          systemImage: checked.contains(index) ? "checkmark.circle.fill" : "circle")
                                        .font(.caption.bold())
                                        .foregroundStyle(checked.contains(index) ? arrangementMint : .white.opacity(0.7))
                                }.buttonStyle(.plain)
                            }
                            Text(section.instruction)
                                .font(.subheadline).foregroundStyle(.white.opacity(0.89))
                            TextField("Your part, transition or texture notes",
                                      text: Binding(
                                        get: { ideas[String(index)] ?? "" },
                                        set: {
                                            ideas[String(index)] = $0
                                            UserDefaults.standard.set(ideas, forKey: noteKey)
                                        }),
                                      axis: .vertical)
                                .lineLimit(2...4)
                                .padding(10)
                                .foregroundStyle(.white)
                                .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 9))
                        }
                        .padding(16)
                        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding(20).padding(.bottom, 40)
            }
        }
        .navigationTitle(lab.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            checked = Set(UserDefaults.standard.array(forKey: doneKey) as? [Int] ?? [])
            ideas = UserDefaults.standard.dictionary(forKey: noteKey) as? [String: String] ?? [:]
        }
    }
}