import threading
import time

from . import VpnContext
from .utils import is_vpn_running, setup_vpn


class VpnThread(threading.Thread):
    def __init__(self, ctx: VpnContext):
        super().__init__()
        self.ctx = ctx

    def run(self):
        while True:
            self.check_connectivity_and_reconfigure()
            self.ctx.storage.persist("region", self.ctx.config.pia_region)
            if self.ctx.config.run_once:
                return
            self.wait_interval()

    def check_connectivity_and_reconfigure(self):
        is_vpn_running_result = is_vpn_running(self.ctx)
        if is_vpn_running_result:
            self.print_vpn_status("UP")

        if not is_vpn_running_result or self.ctx.config.force_setup:
            setup_vpn(self.ctx)
            if is_vpn_running(self.ctx):
                self.print_vpn_status("UP")
            else:
                self.print_vpn_status("DOWN")
                print(f"Failed to setup VPN.")

    def print_vpn_status(self, status):
        print(f"WireGuard interface {self.ctx.config.vpn_interface} is {status}.")

    def wait_interval(self):
        time.sleep(self.ctx.config.vpn_check_connectivity_interval * 60)

