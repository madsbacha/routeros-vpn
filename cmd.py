import argparse
import threading
import time

from config import Config
from context import Context
from threads.connection import ConnectionThread
from pia import Pia
from router import Router
from threads.portforward import PortforwardThread


def run(ctx: Context):
    threads = [ConnectionThread(ctx)]
    if ctx.config.vpn_portforward:
        threads.append(PortforwardThread(ctx))
    start_threads(threads)


def start_threads(threads: [threading.Thread]):
    for thread in threads:
        thread.start()


if __name__ == '__main__':
    from dotenv import load_dotenv
    load_dotenv()
    cfg = Config.load_from_env()
    run(Context(
        router=Router(cfg.router_username, cfg.router_password, cfg.router_host,
                      print_router_response=cfg.print_router_response),
        pia=Pia(cfg.pia_username, cfg.pia_password),
        config=cfg))
