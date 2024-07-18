from config import Config
from pia import Pia
from router import Router


class Context:
    def __init__(self, router: Router, pia: Pia, config: Config):
        self.router = router
        self.pia = pia
        self.config = config
