class PortforwardSession:
    def __init__(self, payload, signature, gateway, port, common_name):
        self.payload = payload
        self.signature = signature
        self.gateway = gateway
        self.port = port
        self.common_name = common_name
