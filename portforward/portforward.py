import threading
import time

from intercom.utils import read_connection, read_portforward, clear_portforward, persist_portforward
from portforward import PortforwardContext
from pia.keepalive_exception import KeepaliveException


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
            self.portforward_session = read_portforward(self.ctx.storage)
        if self.portforward_session is None:
            connection = read_connection(self.ctx.storage)
            region = self.ctx.storage.read("region")
            self.portforward_session = self.ctx.pia.create_portforward_session(
                region,
                connection.gateway,
                connection.endpoint_common_name)
        persist_portforward(self.ctx.storage, self.portforward_session)

        try:
            self.ctx.pia.send_portforward_keepalive(self.portforward_session)
        except KeepaliveException:
            self.portforward_session = None
            clear_portforward(self.ctx.storage)

    def wait_interval(self):
        time.sleep(self.ctx.config.keepalive_interval * 60)
