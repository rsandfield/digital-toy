class_name Tone
extends Resource

enum Note {
    A, B, C, D, E, F, G
}

enum Shift {
    NATURAL, FLAT, SHARP, DOUBLE_FLAT, DOUBLE_SHARP
}

@export var note: Note
@export var shift: Shift
@export var octave: int


func _init(n: Note = Note.C, s: Shift = Shift.NATURAL, o: int = 4):
    note = n
    shift = s
    octave = o

static func from_string(value: String) -> Tone:
    var parts = value.split("-")
    return Tone.new(
        Note.get(parts[1]),
        Shift.get(parts[2]),
        int(parts[0])
    )

static func from_midi_index(value: int, octave_shift: int = -1) -> Tone:
    var index = (value % 12)
    var note_index = 0
    var shift_index = 0
    if index < 5:
        note_index = ((index / 2) + 2) % 7
        if index % 2 == 1:
            shift_index = 2
    else:
        note_index = ((index - 5) / 2) + 3
        if index % 2 == 0:
            shift_index = 2
    return Tone.new(
        note_index,
        shift_index,
        (value / 12) + octave_shift,
    )

func pitch() -> float:
    var octave_diff = octave - 4
    return pow(2.0, octave_diff + note / 6.0) * 440.0

func pitch_correction(input_pitch: float) -> float:
    return pitch() / input_pitch

func _to_string():
    return "%d-%s-%s" % [octave, Note.keys()[note], Shift.keys()[shift]]
