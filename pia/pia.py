from pia.client import Client
from pia.portforward_exception import PortforwardException
from pia.portforward_session import PortforwardSession
from pia.wireguard import WireGuardConnection


class Pia:
    def __init__(self, username, password, debug=False):
        self.client = Client(username, password, debug=debug)

    def get_region(self, region_id):
        servers = self.client.get_servers()
        for server in servers['regions']:
            if server['id'] == region_id:
                return server
        raise Exception(f"Server region {region_id} not found")

    def get_wireguard_port(self):
        servers = self.client.get_servers()
        return servers['groups']['wg'][0]['ports'][0]

    def get_token(self, server_region):
        meta_server = server_region['servers']["meta"][0]
        return self.client.get_token(meta_server["ip"], meta_server["cn"])

    def get_token_v2(self):
        return self.client.get_token_v2()

    def create_portforward_session(self, region, gateway, common_name) -> PortforwardSession:
        server_region = self.get_region(region)
        if not self.region_can_portforward(server_region):
            raise Exception(f"Region {region} does not support portforward")
        token = self.get_token_v2()
        server_ip = gateway
        server_port = 19999
        server_common_name = common_name
        response = self.client.get_signature(server_ip, server_port, server_common_name, token)
        if response["status"] != "OK":
            raise PortforwardException(f"Failed to create portforward session: {response['message']}")
        return PortforwardSession(
            payload=response["payload"],
            signature=response["signature"],
            server_ip=server_ip,
            server_port=server_port,
            server_common_name=server_common_name,
        )

    @staticmethod
    def region_can_portforward(server_region):
        return server_region['port_forward']

    def send_portforward_keepalive(self, session: PortforwardSession):
        self.client.bind_port(session.server_ip, session.server_port, session.server_common_name, session.payload, session.signature)

    def create_wireguard_config(self, region, public_key) -> WireGuardConnection:
        server_region = self.get_region(region)
        token = self.get_token(server_region)
        print("token", token)

        wireguard_server = server_region['servers']["wg"][0]
        port = self.get_wireguard_port()
        connection = self.client.add_key(wireguard_server["ip"], port, wireguard_server["cn"], token, public_key)

        return WireGuardConnection(
            address=connection['peer_ip'],
            peer_public_key=connection['server_key'],
            dns_servers=connection['dns_servers'],
            endpoint_port=port,
            endpoint_address=connection['server_ip'],
            endpoint_common_name=wireguard_server['cn'],
            gateway=connection['server_vip']
        )
