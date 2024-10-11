class_name NodeHelper


static func connect_signal(sig: Signal, node: Node, method_name: String):
    if !node.has_method(method_name):
        return
    var method = Callable(node, method_name)
    if !sig.is_connected(method):
        sig.connect(method)


static func disconnect_signal(sig: Signal, node: Node, method_name: String):
    var method = Callable(node, method_name)
    if sig.is_connected(method):
        sig.disconnect(method)
