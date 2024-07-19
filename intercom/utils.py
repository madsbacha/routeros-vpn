from typing import Optional

from intercom import JsonFile
from pia.portforward_session import PortforwardSession
from pia.wireguard import WireGuardConnection


def persist_connection(storage: JsonFile, connection: WireGuardConnection):
    storage.persist("vpn", connection.to_dict())


def read_connection(storage: JsonFile) -> Optional[WireGuardConnection]:
    data = storage.read("vpn")
    if data is None:
        return None
    return WireGuardConnection.from_dict(data)


def persist_portforward(storage: JsonFile, portforward: PortforwardSession):
    storage.persist("portforward", portforward.to_dict())


def read_portforward(storage: JsonFile) -> Optional[PortforwardSession]:
    data = storage.read("portforward")
    if data is None:
        return None
    return PortforwardSession.from_dict(data)


def clear_portforward(storage: JsonFile):
    storage.remove("portforward")
