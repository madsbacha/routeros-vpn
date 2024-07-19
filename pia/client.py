import json
from urllib import parse

import requests
from requests_toolbelt.adapters import host_header_ssl


class Client:
    def __init__(self, username, password, debug=False):
        self.username = username
        self.password = password
        self.debug = debug
        self.URL_SERVERS = 'https://serverlist.piaservers.net/vpninfo/servers/v4'
        self.URL_TOKEN = "https://{}/authv3/generateToken"
        self.URL_TOKEN_V2 = "https://www.privateinternetaccess.com/api/client/v2/token"
        self.URL_ADD_KEY = "https://{}:{}/addKey?pt={}&pubkey={}"
        self.URL_SIGNATURE = "https://{}:{}/getSignature?token={}"
        self.URL_BIND_PORT = "https://{}:{}/bindPort?payload={}&signature={}"

    def generate_add_key_url(self, server_ip, server_port, token, public_key):
        return self.URL_ADD_KEY.format(server_ip, server_port, parse.quote(token), parse.quote(public_key))

    def generate_bind_port_url(self, server_ip: str, server_port: int, payload: str, signature: str):
        return self.URL_BIND_PORT.format(server_ip, server_port, parse.quote(payload), parse.quote(signature))

    @staticmethod
    def create_request_session():
        request_session = requests.Session()
        request_session.mount('https://', host_header_ssl.HostHeaderSSLAdapter())
        request_session.verify = 'ca.rsa.4096.crt'
        return request_session

    def get_servers(self):
        response = requests.get(self.URL_SERVERS)
        data = json.loads(response.text.splitlines()[0])
        if self.debug:
            print("get_servers", data)
        return data

    def get_token(self, server_ip, server_common_name):
        request_session = self.create_request_session()
        response = request_session.get(self.URL_TOKEN.format(server_ip),
                                       headers={"Host": server_common_name},
                                       auth=(self.username, self.password))
        data = response.json()
        if self.debug:
            print("get_token", data)
        if response.status_code == 200 and data['status'] == 'OK':
            return data['token']
        raise Exception("Failed to generate token")

    def get_token_v2(self):
        response = requests.post(self.URL_TOKEN_V2, data={
            'username': self.username,
            'password': self.password
        })
        data = response.json()
        if self.debug:
            print("get_token_v2", data)
        return data["token"]

    def add_key(self, server_ip, server_port, server_common_name, token, public_key):
        request_session = self.create_request_session()
        response = request_session.get(self.generate_add_key_url(server_ip, server_port, token, public_key),
                                       headers={"Host": server_common_name})
        data = response.json()
        if self.debug:
            print("add_key", data)
        if response.status_code == 200 and data['status'] == 'OK':
            return data
        print(response)
        raise Exception("Failed to add key to PIA WireGuard server")

    def get_signature(self, server_ip: str, server_port: int, server_common_name: str, token: str):
        request_session = self.create_request_session()
        response = request_session.get(self.URL_SIGNATURE.format(server_ip, server_port, token),
                                       headers={"Host": server_common_name})
        data = response.json()
        if self.debug:
            print("get_signature", data)
        if response.status_code == 200 and data['status'] == 'OK':
            return data
        print(response)
        raise Exception("Failed to retrieve signature from PIA")

    def bind_port(self, server_ip: str, server_port: int, server_common_name: str, payload: str, signature: str):
        request_session = self.create_request_session()
        response = request_session.get(self.generate_bind_port_url(server_ip, server_port, payload, signature),
                                       headers={"Host": server_common_name})
        data = response.json()
        if self.debug:
            print("bind_port", data)
        if response.status_code == 200 and data['status'] == 'OK':
            return data
        print(response)
        raise Exception("Failed to bind port")
