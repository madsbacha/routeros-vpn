import base64
import json


class PortforwardSession:
    def __init__(self, payload, signature, server_ip, server_port, server_common_name):
        self.payload = payload
        payload_data = self.decode_payload(payload)
        self.port = payload_data['port']
        self.expires_at = payload_data['expires_at']
        self.signature = signature
        self.server_ip = server_ip
        self.server_port = server_port
        self.server_common_name = server_common_name

    @staticmethod
    def decode_payload(payload):
        return json.loads(base64.b64decode(payload).decode('utf-8'))

    def to_dict(self):
        return {
            'payload': self.payload,
            'signature': self.signature,
            'server_ip': self.server_ip,
            'server_port': self.server_port,
            'server_common_name': self.server_common_name,
            'port': self.port,
            'expires_at': self.expires_at
        }

    @staticmethod
    def from_dict(data) -> 'PortforwardSession':
        return PortforwardSession(
            payload=data['payload'],
            signature=data['signature'],
            server_ip=data['server_ip'],
            server_port=data['server_port'],
            server_common_name=data['server_common_name'],
        )
