class WireGuardConnection:
    def __init__(self, address, peer_public_key, dns_servers, endpoint_address, endpoint_port, endpoint_common_name, gateway):
        self.address = address
        self.peer_public_key = peer_public_key
        self.dns_servers = dns_servers
        self.endpoint_address = endpoint_address
        self.endpoint_port = endpoint_port
        self.endpoint_common_name = endpoint_common_name
        self.gateway = gateway

    def to_dict(self):
        return {
            'address': self.address,
            'peer_public_key': self.peer_public_key,
            'dns_servers': self.dns_servers,
            'endpoint_address': self.endpoint_address,
            'endpoint_port': self.endpoint_port,
            'endpoint_common_name': self.endpoint_common_name,
            'gateway': self.gateway
        }

    @staticmethod
    def from_dict(data) -> 'WireGuardConnection':
        return WireGuardConnection(**data)
