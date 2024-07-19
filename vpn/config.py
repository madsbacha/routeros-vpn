from utils import get_env, get_env_bool, get_env_int


class VpnConfig:
    def __init__(self):
        self.router_username = None
        self.router_password = None
        self.router_host = None
        self.pia_username = None
        self.pia_password = None
        self.pia_region = None
        self.vpn_interface = None
        self.vpn_ping_count = None
        self.vpn_ping_ip = None
        self.vpn_listen_port = None
        self.vpn_check_connectivity_interval = None
        self.print_router_response = None
        self.run_once = None
        self.force_setup = None

    @staticmethod
    def load_from_env():
        cfg = VpnConfig()

        cfg.router_username = get_env('ROUTER_USERNAME', required=True)
        cfg.router_password = get_env('ROUTER_PASSWORD', required=True)
        cfg.router_host = get_env('ROUTER_HOST', required=True)

        cfg.pia_username = get_env('PIA_USERNAME', required=True)
        cfg.pia_password = get_env('PIA_PASSWORD', required=True)
        cfg.pia_region = get_env('PIA_REGION', required=True)

        cfg.vpn_interface = get_env('VPN_INTERFACE', required=True)
        cfg.vpn_ping_count = get_env_int('VPN_PING_COUNT', default=2)
        cfg.vpn_ping_ip = get_env('VPN_PING_IP', default='1.1.1.1')
        cfg.vpn_listen_port = get_env_int('VPN_LISTEN_PORT', default=13231)
        cfg.vpn_check_connectivity_interval = get_env_int('VPN_CHECK_CONNECTIVITY_INTERVAL', default=5)

        cfg.print_router_response = get_env_bool('DEBUG_ROUTER')
        cfg.run_once = get_env_bool('RUN_ONCE', default=False)
        cfg.force_setup = get_env_bool('FORCE_SETUP', default=False)
        return cfg
