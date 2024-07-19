import json
from urllib import parse

import requests
from requests_toolbelt.adapters import host_header_ssl

from pia.wireguard import WireGuardConnection


class Pia:
    def __init__(self, username, password):
        self.username = username
        self.password = password
        self.URL_SERVERS = 'https://serverlist.piaservers.net/vpninfo/servers/v4'
        self.URL_TOKEN = "https://{}/authv3/generateToken"
        self.URL_ADD_KEY = "https://{}:{}/addKey?pt={}&pubkey={}"

    def get_servers(self):
        response = requests.get(self.URL_SERVERS)
        return json.loads(response.text.splitlines()[0])

    def get_region(self, region_id):
        servers = self.get_servers()
        for server in servers['regions']:
            if server['id'] == region_id:
                return server
        raise Exception(f"Server region {region_id} not found")

    def get_wireguard_port(self):
        servers = self.get_servers()
        return servers['groups']['wg'][0]['ports'][0]

    def get_token(self, server_ip, server_common_name):
        request_session = self.create_request_session()
        response = request_session.get(self.URL_TOKEN.format(server_ip),
                                       headers={"Host": server_common_name},
                                       auth=(self.username, self.password))
        data = response.json()
        if response.status_code == 200 and data['status'] == 'OK':
            return data['token']
        raise Exception("Failed to generate token")

    @staticmethod
    def create_request_session():
        request_session = requests.Session()
        request_session.mount('https://', host_header_ssl.HostHeaderSSLAdapter())
        request_session.verify = 'ca.rsa.4096.crt'
        return request_session

    def generate_add_key_url(self, server_ip, server_port, token, public_key):
        return self.URL_ADD_KEY.format(server_ip, server_port, parse.quote(token), parse.quote(public_key))

    def add_key(self, server_ip, server_port, server_common_name, token, public_key):
        request_session = self.create_request_session()
        response = request_session.get(self.generate_add_key_url(server_ip, server_port, token, public_key),
                                       headers={"Host": server_common_name})
        data = response.json()
        if response.status_code == 200 and data['status'] == 'OK':
            return data
        print(response)
        raise Exception("Failed to add key to PIA WireGuard server")

    def register_port(self):
        pass

    def create_wireguard_config(self, region, public_key) -> WireGuardConnection:
        server_region = self.get_region(region)

        meta_server = server_region['servers']["meta"][0]
        token = self.get_token(meta_server["ip"], meta_server["cn"])

        wireguard_server = server_region['servers']["wg"][0]
        port = self.get_wireguard_port()
        connection = self.add_key(wireguard_server["ip"], port, wireguard_server["cn"], token, public_key)

        return WireGuardConnection(
            address=connection['peer_ip'],
            peer_public_key=connection['server_key'],
            dns_servers=connection['dns_servers'],
            endpoint_port=port,
            endpoint_address=connection['server_ip']
        )
