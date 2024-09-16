class_name Speaker
extends Node3D

var audio = _get_stream_player()

var playback: AudioStreamGeneratorPlayback
var sig: GameSignal
var time: float


func _ready():
    if audio:
        audio.play()
        playback = audio.get_stream_playback()


func _process(delta):
    time += delta
    
    if sig && audio:
        _push_buffer(delta)


func _push_buffer(delta: float):
    var buffer_size = audio.mix_rate * delta
    var inc = 1 / audio.mix_rate

    var buffer = PackedVector2Array(buffer_size)
    for i in range(buffer_size):
        var phase = time + i * inc
        buffer[i] = (sig.value(phase))
    playback.push_buffer(buffer)


func _get_stream_player() -> AudioStreamPlayer:
    var children = _get_stream_players()
    if len(children) == 0:
        return
    return children[0]


func _get_stream_players() -> Array[Node]:
    return find_children("", "AudioStreamPlayer")


func _get_configuration_warning():
    if len(_get_stream_players()) == 0:
        return "Speaker requires an AudioStreamPlayer child"
