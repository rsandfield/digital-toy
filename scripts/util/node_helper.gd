class_name NodeHelper


static func connect_signal(sig: Signal, node: Node, method_name: String, bind = null):
    if !node.has_method(method_name):
        return
    var method = Callable(node, method_name)
    if bind:
        method.bind(bind)
    if !sig.is_connected(method):
        sig.connect(method)


static func disconnect_signal(sig: Signal, node: Node, method_name: String):
    var method = Callable(node, method_name)
    if sig.is_connected(method):
        sig.disconnect(method)


static func find_duck_child(node: Node, method_name: String, recursive: bool = true):
    for child in node.get_children():
        if child.has_method(method_name):
            return child
        if recursive:
            var maybe = find_duck_child(child, method_name)
            if maybe:
                return maybe
    return null