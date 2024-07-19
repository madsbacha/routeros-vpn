import argparse
import threading

from portforward import PortforwardConfig, PortforwardContext, PortforwardThread
from vpn import VpnConfig, VpnContext, VpnThread


def run(mode: str):
    threads = []
    if mode == 'vpn':
        threads.append(create_vpn_thread())
    elif mode == 'portforward':
        threads.append(create_portforward_thread())
    else:
        raise Exception('Invalid mode')
    start_threads(threads)


def create_vpn_thread():
    cfg = VpnConfig.load_from_env()
    ctx = VpnContext.create_from_config(cfg)
    return VpnThread(ctx)


def create_portforward_thread():
    cfg = PortforwardConfig.load_from_env()
    ctx = PortforwardContext.create_from_config(cfg)
    return PortforwardThread(ctx)


def start_threads(threads: [threading.Thread]):
    for thread in threads:
        thread.start()


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('mode', help='Specify mode of program.')
    args = parser.parse_args()

    from dotenv import load_dotenv
    load_dotenv()
    run(args.mode)
