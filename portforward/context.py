from intercom import JsonFile
from pia import Pia
from portforward import PortforwardConfig


class PortforwardContext:
    def __init__(self, pia: Pia, storage: JsonFile, config: PortforwardConfig):
        self.pia = pia
        self.config = config
        self.storage = storage

    @staticmethod
    def create_from_config(config: PortforwardConfig):
        return PortforwardContext(
            pia=Pia(config.pia_username, config.pia_password, config.print_pia_response),
            storage=JsonFile(config.storage_file),
            config=config)
