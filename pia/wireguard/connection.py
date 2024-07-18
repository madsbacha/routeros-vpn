class WireGuardConnection:
    def __init__(self, address, peer_public_key, dns_servers, endpoint_address, endpoint_port):
        self.address = address
        self.peer_public_key = peer_public_key
        self.dns_servers = dns_servers
        self.endpoint_address = endpoint_address
        self.endpoint_port = endpoint_port
