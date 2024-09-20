class_name Tone
extends Resource

enum Note {
    A, B, C, D, E, F, G
}

enum Shift {
    Natural, Flat, Sharp, DoubleFlat, DoubleSharp
}

@export var note: Note
@export var shift: Shift
@export var octave: int


func _init(n: Note = Note.C, s: Shift = Shift.Natural, o: int = 4):
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

func pitch() -> float:
    var octave_diff = octave - 4
    return pow(2.0, octave_diff + note / 6.0) * 440.0

func pitch_correction(input_pitch: float) -> float:
    return pitch() / input_pitch

func _to_string():
    return "%d-%s-%s" % [octave, Note.keys()[note], Shift.keys()[shift]]
