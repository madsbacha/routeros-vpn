from pia import Pia
from portforward import PortforwardConfig


class PortforwardContext:
    def __init__(self, pia: Pia, config: PortforwardConfig):
        self.pia = pia
        self.config = config

    @staticmethod
    def create_from_config(config: PortforwardConfig):
        return PortforwardContext(
            pia=Pia(config.pia_username, config.pia_password, config.print_pia_response),
            config=config)
