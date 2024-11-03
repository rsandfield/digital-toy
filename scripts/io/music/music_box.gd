class_name MusicBox
extends Node


@export var midi: MidiResource

var _player: MidiPlayer
var _note_players = {}


func _ready():
    for sibling in get_parent().get_children():
        if sibling.has_method("get_tone") && sibling.has_method("play"):
            var tone: Tone = sibling.get_tone()
            _note_players.get_or_add(tone.to_string(), []).append(sibling)
    _player = MidiPlayer.new()
    _player.midi = midi
    add_child(_player)
    _player.note.connect(_on_midi_player_note)


func play():
    _player.play()


func _on_midi_player_note(event, _track):
    if (event['subtype'] == MIDI_MESSAGE_NOTE_ON):
        var tone = Tone.from_midi_index(event.note)
        var notes = _note_players.get(tone.to_string())
        if !notes:
            return
        for note in notes:
            note.play()
