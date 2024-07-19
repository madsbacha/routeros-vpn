from routeros import login, RouterOS

from router.domain import Address, Ping
from router.domain.wireguard import Peer


class Router:
    def __init__(self, username, password, host, print_router_response=None):
        self.username = username
        self.password = password
        self.host = host
        self.print_router_response = False
        if print_router_response is not None:
            self.print_router_response = print_router_response

    def _create_router_client(self) -> RouterOS:
        return login(self.username, self.password, self.host)

    def has_wireguard_interface(self, interface: str) -> bool:
        client = self._create_router_client()
        response = client.query('/interface/wireguard/print').equal(**{"name": interface})
        if self.print_router_response:
            print("has_wireguard_interface", response)
        client.close()
        return len(response) > 0

    def ping(self, address, count, interface) -> [Ping]:
        client = self._create_router_client()
        response = client("/ping", address=address, count=count, interface=interface)
        if self.print_router_response:
            print("ping", response)
        client.close()
        pings = []
        for item in response:
            pings.append(Ping.from_dict(item))
        return pings

    def get_wireguard_peers(self, interface: str) -> [Peer]:
        client = self._create_router_client()
        response = client.query('/interface/wireguard/peers/print').equal(**{"interface": interface})
        if self.print_router_response:
            print("get_wireguard_peers", response)
        client.close()
        peers = []
        for item in response:
            peers.append(Peer.from_dict(item))
        return peers

    def clear_wireguard_peers(self, interface: str):
        client = self._create_router_client()
        peers = client.query("/interface/wireguard/peers/print").equal(interface=interface)
        if self.print_router_response:
            print("clear_wireguard_peers", peers)
        for peer in peers:
            client("/interface/wireguard/peers/remove", **{".id": peer[".id"]})
        client.close()

    def remove_address_from_interface(self, interface):
        client = self._create_router_client()
        existing = client.query("/ip/address/print").equal(interface=interface)
        if self.print_router_response:
            print("remove_address_from_interface", existing)
        for address in existing:
            client("/ip/address/remove", **{".id": address[".id"]})
        client.close()

    def create_wireguard_interface(self, name, listen_port, private_key=None, comment=None):
        client = self._create_router_client()
        args = {
            "listen-port": listen_port,
            "name": name,
        }
        if private_key is not None:
            args["private-key"] = private_key
        if comment is not None:
            args["comment"] = comment
        response = client("/interface/wireguard/add", **args)
        if self.print_router_response:
            print("create_wireguard_interface", response)
        client.close()

    def get_wireguard_interface_public_key(self, name):
        client = self._create_router_client()
        interface = client.query('/interface/wireguard/print').equal(name=name)
        if self.print_router_response:
            print("get_wireguard_public_key", interface)
        if len(interface) != 1:
            raise Exception(f"Error looking for WireGuard interface {name}")
        client.close()
        return interface[0]["public-key"]

    def create_address(self, address: Address):
        client = self._create_router_client()
        response = client("/ip/address/add", **address.to_dict())
        if self.print_router_response:
            print("create_address", response)
        client.close()
        return response['ret']

    def create_wireguard_peer(self, peer: Peer):
        client = self._create_router_client()
        response = client("/interface/wireguard/peers/add", **peer.to_dict())
        if self.print_router_response:
            print("create_wireguard_peer", response)
        client.close()
        return response[0]['ret']

    def update_wireguard_peer(self, idx: str, peer: Peer) -> bool:
        client = self._create_router_client()
        response = client("/interface/wireguard/peers/set", **{".id": idx}, **peer.to_dict())
        if self.print_router_response:
            print("update_wireguard_peer", response)
        client.close()
        return len(response) == 0

    def get_addresses(self, interface) -> [Address]:
        client = self._create_router_client()
        response = client.query("/ip/address/print").equal(interface=interface)
        if self.print_router_response:
            print("get_addresses", response)
        client.close()
        addresses = []
        for item in response:
            addresses.append(Address.from_dict(item))
        return addresses

    def update_address(self, idx: str, address: Address) -> bool:
        client = self._create_router_client()
        response = client("/ip/address/set", **{".id": idx}, **address.to_dict())
        if self.print_router_response:
            print("update_address", response)
        client.close()
        return len(response) == 0
