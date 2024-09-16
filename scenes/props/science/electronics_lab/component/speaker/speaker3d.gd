class_name Speaker3D
extends Component

var audio: AudioStreamPlayer3D
var playback: AudioStreamGeneratorPlayback
var mix_rate: float
var max_frames: float
var time: float
var phase: float

func _ready():
	super._ready()
	audio = _get_stream_player()
	if audio:
		audio.play()
		playback = audio.get_stream_playback()
		mix_rate = audio.stream.mix_rate
		_fill_buffer()


func _process(delta):
	time += delta

	if inputs[0] && audio:
		_fill_buffer()

func _fill_buffer():
	var buffer_size = playback.get_frames_available()
	var inc = 1.0 / mix_rate

	var buffer = PackedVector2Array()
	buffer.resize(buffer_size)
	for i in range(buffer_size):
		phase += inc
		buffer[i] = get_value_at_time(phase) * Vector2.ONE
	playback.push_buffer(buffer)


func _get_stream_player() -> AudioStreamPlayer3D:
	var children = _get_stream_players()
	if len(children) == 0:
		return
	return children[0]


func _get_stream_players() -> Array[Node]:
	return find_children("", "AudioStreamPlayer3D")


func _get_configuration_warning():
	if len(_get_stream_players()) == 0:
		return "Speaker requires an AudioStreamPlayer child"
