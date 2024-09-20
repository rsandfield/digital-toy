class_name Score

var bpm: float = 120
var _score = []


static func from_text_file(filepath: String) -> Score:
    var newScore = Score.new()
    if !FileAccess.file_exists(filepath):
        push_error("File '%s' does not exist" % filepath)
        return newScore
    var f = FileAccess.open(filepath, FileAccess.READ)
    for line in f.get_as_text().split("\n"):
        var chord = []
        var noteStrings = line.split(",")
        for tone in noteStrings:
            if len(tone) == 0:
                continue
            chord.append(Tone.from_string(tone))
        newScore._score.append(chord)
    return newScore


func out_of_range(index: int) -> bool:
    return index < 0 || index >= len(_score)


func chord_at_index(index: int) -> Array[Tone]:
    if out_of_range(index):
        return []
    print(_score[index])
    var chord: Array[Tone]
    chord.assign(_score[index])
    return chord


func chord_at_time(time: float) -> Array[Tone]:
    return chord_at_index(int(time * bpm / 60.0))
