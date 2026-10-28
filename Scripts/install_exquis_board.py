#!/usr/bin/env python3
"""Safe no-backup Exquis overlay installer for Desktop ConsciousConnection.
Copy source image + key map from user files; modify only Keys Studio views.
No merges, checkout, app deletion or existing audio changes.
"""
from pathlib import Path
import json, subprocess, tempfile, sys, textwrap

ROOT=Path.home()/"Desktop/ConsciousConnection"
APP=ROOT/"ConsciousConnection"
PLAY=APP/"KeysStudioPlayView.swift"
STUDIO=APP/"CreateMusicStudioView.swift"
BOARD=APP/"ExquisChordBoard.swift"
ASSET=APP/"Assets.xcassets/ExquisBoard.imageset"
MAP=APP/"ExquisBoardMap.json"

def stop(msg):
    sys.exit("SAFE STOP: "+msg+"\nNo app files changed.")

def find_file(filename):
    bases=[Path.home()/"Downloads", Path.home()/"Desktop"]
    candidates=[]
    for base in bases:
        if not base.exists(): continue
        candidates.extend([base/filename])
        candidates.extend(base.glob("*/"+filename))
        candidates.extend(base.glob("*/*/"+filename))
    found=next((p for p in candidates if p.is_file()),None)
    if found: print("Found:",found); return found
    print("Select your original "+filename+" in Finder.")
    result=subprocess.run(["osascript","-e",
        'POSIX path of (choose file with prompt "Select '+filename+'")'],
        text=True,capture_output=True)
    if result.returncode or not result.stdout.strip(): stop("File selection cancelled: "+filename)
    path=Path(result.stdout.strip())
    if not path.is_file() or path.name.lower()!=filename.lower():
        stop("Selected file is not "+filename)
    return path

def fetch_feature(path):
    result=subprocess.run(["git","show","FETCH_HEAD:"+path],
                          cwd=ROOT,capture_output=True)
    if result.returncode: stop("Approved feature file unavailable: "+path)
    return result.stdout

def one(source,old,new,label):
    if source.count(old)!=1: stop("Unexpected "+label)
    return source.replace(old,new,1)

def replace_view_call(source,name):
    needle=name+"("
    if source.count(needle)!=1:
        stop("Expected exactly one "+name+" view in its screen.")
    pos=source.index(needle)
    begin=source.rfind("\n",0,pos)+1
    indent=source[begin:pos]
    if indent.strip(): stop("Unexpected indentation around "+name)
    depth=0;end=None
    for i in range(pos,len(source)):
        if source[i]=="(":depth+=1
        elif source[i]==")":
            depth-=1
            if depth==0: end=i+1; break
    if end is None: stop("Incomplete Swift view call: "+name)
    original=source[pos:end]
    if name=="KeysPerformanceKeyboard": extra=""
    else: extra="\n"+indent+"        .frame(height: 220)"
    chosen=(
        indent+'if boardMode == "Exquis" {\n'+
        indent+'    ExquisChordBoard(labID: lab.id,\n'+
        indent+'                     chordIndex: '+('currentChordIndex' if name!='MinilogueChordDiagram' and 'KeysPerformance' in name or 'curated' in name.lower() else 'chordIndex')+',\n'+
        indent+'                     chord: chord,\n'+
        indent+'                     omitRoot: '+('omitRoot' if name=="KeysPerformanceKeyboard" else 'rootless')+')'+extra+'\n'+
        indent+'} else {\n'+indent+'    '+original.replace("\n","\n    ")+
        '\n'+indent+'}'
    )
    # The caller knows its index/omitRoot variables.
    return source[:begin]+chosen+source[end:]

def wrap_call(source,name,index,omit,portrait):
    needle=name+"("
    if source.count(needle)!=1: stop("Expected one "+name+" chord display")
    pos=source.index(needle)
    line_start=source.rfind("\n",0,pos)+1
    indent=source[line_start:pos]
    if indent.strip(): stop("Unexpected indentation for "+name)
    depth=0;end=None
    for i in range(pos,len(source)):
        if source[i]=="(": depth+=1
        elif source[i]==")":
            depth-=1
            if depth==0: end=i+1;break
    if end is None: stop("Incomplete "+name+" call")
    original=source[pos:end]
    original_indented=original.replace("\n","\n    ")
    replacement=(
        indent+'Group {\n'+
        indent+'    if boardMode == "Exquis" {\n'+
        indent+'        ExquisChordBoard(labID: lab.id,\n'+
        indent+'                         chordIndex: '+index+',\n'+
        indent+'                         chord: chord,\n'+
        indent+'                         omitRoot: '+omit+')'+
        ('\n'+indent+'            .frame(height: 220)' if portrait else '')+
        '\n'+indent+'    } else {\n'+
        indent+'        '+original_indented+'\n'+
        indent+'    }\n'+
        indent+'}'
    )
    return source[:line_start]+replacement+source[end:]

def main():
    if not PLAY.is_file() or not STUDIO.is_file() or not (APP/"CuratedMinilogueKeyboard.swift").exists():
        stop("The current Keys Studio wasn't found.")
    if not (APP/"Keys_Studio_Hand_Assignments.json").is_file():
        stop("Reviewed Keys Studio voicings weren't found.")

    p_old,p=PLAY.read_text(),PLAY.read_text()
    s_old,s=STUDIO.read_text(),STUDIO.read_text()
    if "EXQUIS_MODE_PICKER_V1" in p:
        print("Exquis mode already installed. No changes.");return

    image=find_file("Exquis-keys.jpg")
    mapped=find_file("exquis-map.json")
    data=json.loads(mapped.read_text())
    keys=data.get("keys")
    if not isinstance(keys,list) or len(keys)!=61:
        stop("Expected 61 calibrated Exquis hexagon positions.")
    if sorted(k.get("idx") for k in keys)!=list(range(61)):
        stop("Exquis keys must have unique indices 0 through 60.")
    if any(not isinstance(k.get("note"),str) or not 0<=k.get("x",-1)<=1
           or not 0<=k.get("y",-1)<=1 for k in keys):
        stop("Invalid Exquis note labels or coordinates.")
    if not image.read_bytes().startswith(b"\xff\xd8"):
        stop("The Exquis photo is not a JPEG.")
    # The mapping uses normalized x/y coordinates, so exported copies of
    # the same photo may have different pixel dimensions. Check the aspect
    # ratio rather than insisting on the original image's exact dimensions.
    dimensions=subprocess.run(["sips","-g","pixelWidth","-g","pixelHeight",str(image)],
                              capture_output=True,text=True)
    import re
    width_match=re.search(r"pixelWidth:\s*(\d+)",dimensions.stdout)
    height_match=re.search(r"pixelHeight:\s*(\d+)",dimensions.stdout)
    if dimensions.returncode or not width_match or not height_match:
        stop("Could not read the Exquis photo dimensions.")
    width,height=int(width_match.group(1)),int(height_match.group(1))
    print(f"Exquis photo size: {width} x {height} pixels")
    if width<100 or height<100 or abs(width/height - 1754/1241)>0.03:
        stop("The Exquis photo has a different aspect ratio from the calibrated map.")

    p=one(p,'    @StateObject private var player = KeysStudioLoopPlayer()\n',
           '    @StateObject private var player = KeysStudioLoopPlayer()\n'
           '    // EXQUIS_MODE_PICKER_V1\n'
           '    @AppStorage("KeysStudioBoardMode") private var boardMode = "Piano"\n',
           "Play state")
    p=one(p,'                    Toggle("Hear piano chords", isOn: $hearPiano)',
          '                    KeysBoardModePicker(selection: $boardMode)\n'
          '                    Toggle("Hear piano chords", isOn: $hearPiano)',
          "Play controls")
    p=p.replace("The piano sound uses the exact notes highlighted for each hand. Switch it off when you want to play those chords yourself.",
                "The optional piano preview plays the same chords with either keyboard display.")
    p=wrap_call(p,"CuratedMinilogueKeyboard","currentChordIndex","omitRoot",portrait=True)
    # Current landscape performance renderer has its own keyboard drawing.
    if "KeysPerformanceKeyboard(" in p:
        p=wrap_call(p,"KeysPerformanceKeyboard","currentChordIndex","omitRoot",portrait=False)
    elif "keysFullWidthStage" in p:
        stop("An unrecognised performance keyboard is present; refusing to hide it.")
    else:
        stop("Landscape performance screen not found.")

    s=one(s,'struct MusicLabListView: View {\n    let instrument: String\n',
        'struct MusicLabListView: View {\n    let instrument: String\n'
        '    @AppStorage("KeysStudioBoardMode") private var boardMode = "Piano"\n',
        "Keys list state")
    s=one(s,'                TextField("Find a sound, key or lesson", text: $search)',
        '                if instrument == "keys" {\n'
        '                    KeysBoardModePicker(selection: $boardMode)\n'
        '                }\n'
        '                TextField("Find a sound, key or lesson", text: $search)',
        "Keys list controls")
    s=one(s,'struct MusicLabDetailView: View {\n    let lab: MusicLab\n',
        'struct MusicLabDetailView: View {\n    let lab: MusicLab\n'
        '    @AppStorage("KeysStudioBoardMode") private var boardMode = "Piano"\n',
        "Keys lesson state")
    s=one(s,'    private func chordPanel(_ chord: MusicChord) -> some View {',
        '    private func chordPanel(_ chord: MusicChord) -> some View {',
        "Keys chord panel")
    # A picker within the lab lets you switch without navigating back.
    s=one(s,'            ScrollView(.horizontal, showsIndicators: false) {\n'
            '                HStack(spacing: 7) {',
        '            KeysBoardModePicker(selection: $boardMode)\n'
        '            ScrollView(.horizontal, showsIndicators: false) {\n'
        '                HStack(spacing: 7) {',
        "Keys chord selector")
    s=s.replace('Text("MINILOGUE · CHORD SHAPE")',
                'Text(boardMode == "Exquis" ? "EXQUIS · CHORD SHAPE" : "MINILOGUE · CHORD SHAPE")')
    if "CuratedMinilogueKeyboard(" in s:
        s=wrap_call(s,"CuratedMinilogueKeyboard","chordIndex","rootless",portrait=True)
    elif "MinilogueChordDiagram(" in s:
        s=wrap_call(s,"MinilogueChordDiagram","chordIndex","rootless",portrait=True)
    else:
        stop("The Keys lesson chord diagram is unrecognised.")

    swift=fetch_feature("ConsciousConnection/ExquisChordBoard.swift")
    if BOARD.exists() and BOARD.read_bytes()!=swift:
        stop("Existing ExquisChordBoard.swift differs.")
    contents=json.dumps({"images":[{"filename":"Exquis-keys.jpg","idiom":"universal"}],
                         "info":{"author":"xcode","version":1}},indent=2)+"\n"
    if ASSET.exists():
        if (ASSET/"Contents.json").read_text()!=contents or (ASSET/"Exquis-keys.jpg").read_bytes()!=image.read_bytes():
            stop("An existing Exquis asset differs.")
    map_bytes=json.dumps({"keys":keys},ensure_ascii=False,indent=2).encode()+"\n".encode()
    if MAP.exists() and MAP.read_bytes()!=map_bytes:
        stop("An existing Exquis map differs.")

    with tempfile.TemporaryDirectory() as tmp:
        t=Path(tmp)
        for path,content in ((t/"KeysStudioPlayView.swift",p),(t/"CreateMusicStudioView.swift",s)):
            path.write_text(content)
        (t/"ExquisChordBoard.swift").write_bytes(swift)
        parse=subprocess.run(["xcrun","swiftc","-frontend","-parse",
            str(t/"KeysStudioPlayView.swift"),str(t/"CreateMusicStudioView.swift"),
            str(t/"ExquisChordBoard.swift")],capture_output=True,text=True)
        if parse.returncode: stop("Swift syntax check failed:\n"+parse.stderr[-1800:])

    created=[]
    try:
        if not BOARD.exists(): BOARD.write_bytes(swift); created.append(BOARD)
        if not MAP.exists(): MAP.write_bytes(map_bytes); created.append(MAP)
        if not ASSET.exists(): ASSET.mkdir(); created.append(ASSET)
        if not (ASSET/"Contents.json").exists():
            (ASSET/"Contents.json").write_text(contents);created.append(ASSET/"Contents.json")
        if not (ASSET/"Exquis-keys.jpg").exists():
            (ASSET/"Exquis-keys.jpg").write_bytes(image.read_bytes());created.append(ASSET/"Exquis-keys.jpg")
        STUDIO.write_text(s)
        PLAY.write_text(p)
    except Exception:
        STUDIO.write_text(s_old)
        PLAY.write_text(p_old)
        for f in reversed(created):
            if f.is_dir(): f.rmdir()
            else: f.unlink(missing_ok=True)
        raise
    print("\n✓ Exquis added to Keys Studio: Piano / Exquis")
    print("✓ Uses your 61-pad calibration and original Exquis photo")
    print("✓ Mint chord notes; gold root (all matching octaves)")
    print("✓ No fingers / hand colours / MIDI / audio changes on Exquis")
    print("✓ Same existing grooves, chord timing and landscape Play mode")
    print("✓ No backups or git merges. Rebuild your app in Xcode with ⌘R")

if __name__=="__main__":
    main()
