import argparse
import time

from config import Config
from context import Context
from main import is_vpn_running, setup_vpn
from pia import Pia
from router import Router
from router.utils import check_connectivity


def run(ctx: Context, interval: int, once: bool):
    while True:
        if is_vpn_running(ctx):
            print(f"WireGuard interface {ctx.config.vpn_interface} is UP.")
        else:
            setup_vpn(ctx)
            if check_connectivity(ctx.router, ip=ctx.config.vpn_ping_ip, count=ctx.config.vpn_ping_count, interface=ctx.config.vpn_interface):
                print(f"WireGuard interface {ctx.config.vpn_interface} is UP.")
            else:
                print(f"Failed to setup VPN.")
        if once:
            return
        time.sleep(interval * 60)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(prog='RouterOS VPN')
    parser.add_argument("--once", action='store_true', default=False)
    parser.add_argument("--interval", type=int, default=15, help="Minutes between checking connectivity")
    args = parser.parse_args()

    from dotenv import load_dotenv
    load_dotenv()
    cfg = Config.load_from_env()
    run(Context(
        router=Router(cfg.router_username, cfg.router_password, cfg.router_host,
                      print_router_response=cfg.print_router_response),
        pia=Pia(cfg.pia_username, cfg.pia_password),
        config=cfg), args.interval, args.once)
