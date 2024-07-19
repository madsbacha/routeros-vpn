import threading
import time

from context import Context


class PortforwardThread(threading.Thread):
    def __init__(self, ctx: Context):
        super().__init__()
        self.ctx = ctx

    def run(self):
        while True:
            self.send_keepalive()
            if self.ctx.config.run_once:
                return
            self.wait_interval()

    def send_keepalive(self):
        pass

    def wait_interval(self):
        time.sleep(self.ctx.config.vpn_portforward_keepalive_interval * 60)
