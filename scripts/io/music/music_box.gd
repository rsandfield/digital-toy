class_name MusicBox
extends Node


@export var delay: float = 0
@export var score_filepath: String

var _score: Score

var playing = false
var index: int = 0
var playtime: float = 0

var players = {}

func _ready():
    _score = Score.from_text_file(score_filepath)
    for sibling in get_parent().get_children():
        if sibling.has_method("get_tone") && sibling.has_method("play"):
            var tone: Tone = sibling.get_tone()
            players.get_or_add(tone.to_string(), []).append(sibling)


func _process(delta):
    if !playing:
        return
    playtime += delta
    if (playtime * _score.bpm / 60) > (index + delay):
        if _score.out_of_range(index):
            playing = false
            return
        _play_chord(_score.chord_at_index(index))
        index += 1


func _play_chord(tones: Array[Tone]):
    for tone in tones:
        _play_tone(tone)


func _play_tone(tone: Tone):
    for player in players.get(tone.to_string(), []):
        player.play()


func play():
    playing = true
    index = 0
    playtime = 0
