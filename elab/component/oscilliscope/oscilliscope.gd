class_name Oscilliscope
extends Component

@onready var display: WaveFormDisplay = $WaveScreen/SubViewport/WaveFormDisplay

func _ready():
	super._ready()
	display.input = SignalCarrierSignal.new(self)


func _to_string():
	return name