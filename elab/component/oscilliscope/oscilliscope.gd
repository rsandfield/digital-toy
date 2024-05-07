class_name Oscilliscope
extends Component

@export var display: WaveFormDisplay


func _ready():
	super._ready()
	display.input = SignalCarrierSignal.new(self)


func _to_string():
	return name