class_name FrequencyGenerator
extends Component

@export var waveform: WaveForm
@export var active_property_buttons: Array[Button3D]
var activeProperty = 0

func _ready():
    super._ready()
    set_active_property(0)
    _update_display()

func get_value_at_time(t: float) -> float:
    return waveform.get_value_at_time(t)

func set_active_property(index: int):
    activeProperty = index
    for i in len(active_property_buttons):
        active_property_buttons[i].set_lit(i == index)

func add_value_to_active_property(value: float):
    match activeProperty:
        0:
            waveform.frequency += value
        1:
            waveform.amplitude += value
        2:
            waveform.offset += value
        3: 
            waveform.speed += value
    _update_display()

func _update_display():
    $Frequency/Display/Label3D.text = "%.2f" % (waveform.frequency)
    $Voltage/Display/Label3D.text = "%.2f" % (waveform.amplitude)