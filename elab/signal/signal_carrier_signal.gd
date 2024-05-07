class_name SignalCarrierSignal
extends GameSignal

var carrier: SignalCarrier3D

func _init(signalCarrier: SignalCarrier3D):
    carrier = signalCarrier


func get_value_at_time(t: float) -> float:
    return carrier.get_value_at_time(t)


func _to_string():
    return "GameSignal[%s]" % carrier.name
