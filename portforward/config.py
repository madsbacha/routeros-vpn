import os

from utils import get_env_int, get_env, get_env_bool


class PortforwardConfig:
    def __init__(self):
        self.pia_username = None
        self.pia_password = None
        self.pia_region = None
        self.vpn_portforward_gateway = None
        self.vpn_portforward_common_name = None
        self.keepalive_interval = None
        self.run_once = None
        self.print_pia_response = None

    @staticmethod
    def load_from_env():
        cfg = PortforwardConfig()

        cfg.pia_username = get_env('PIA_USERNAME', required=True)
        cfg.pia_password = get_env('PIA_PASSWORD', required=True)
        cfg.pia_region = get_env('PIA_REGION', required=True)

        cfg.vpn_portforward_gateway = get_env('VPN_PORTFORWARD_GATEWAY', required=True)
        cfg.vpn_portforward_common_name = get_env('VPN_PORTFORWARD_COMMON_NAME', required=True)
        cfg.keepalive_interval = get_env_int('VPN_PORTFORWARD_KEEPALIVE_INTERVAL', default=15)

        cfg.print_pia_response = get_env_bool('DEBUG_PIA')
        cfg.run_once = get_env_bool('RUN_ONCE', default=False)
        return cfg
