import threading
import time

from portforward import PortforwardContext


class PortforwardThread(threading.Thread):
    def __init__(self, ctx: PortforwardContext):
        super().__init__()
        self.ctx = ctx
        self.portforward_session = None

    def run(self):
        while True:
            self.send_keepalive()
            if self.ctx.config.run_once:
                return
            self.wait_interval()

    def send_keepalive(self):
        if self.portforward_session is None:
            self.portforward_session = self.ctx.pia.create_portforward_session(
                self.ctx.config.pia_region,
                self.ctx.config.vpn_portforward_gateway,
                self.ctx.config.vpn_portforward_common_name)
        self.ctx.pia.send_portforward_keepalive(self.portforward_session)

    def wait_interval(self):
        time.sleep(self.ctx.config.keepalive_interval * 60)
