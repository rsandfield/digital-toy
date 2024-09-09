class_name Terminal
extends SignalCarrier3D

@export var connection: Connector
var component: Component
var index: int


func register_connection(c: Connector):
    if connection:
        connection.deregister_terminal(self)
    connection = c


func register_component(c: Component, i: int):
    component = c
    index = i


func component_name():
    if component:
        return component.name
    return "null"