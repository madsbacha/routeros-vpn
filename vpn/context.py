from pia import Pia
from router import Router
from vpn import VpnConfig


class VpnContext:
    def __init__(self, router: Router, pia: Pia, config: VpnConfig):
        self.router = router
        self.pia = pia
        self.config = config

    @staticmethod
    def create_from_config(config: VpnConfig):
        return VpnContext(
            router=Router(config.router_username, config.router_password, config.router_host,
                          print_router_response=config.print_router_response),
            pia=Pia(config.pia_username, config.pia_password, config.print_pia_response),
            config=config)
