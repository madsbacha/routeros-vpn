from router import Router
from router.domain import Ping


def gateway_from_ip(ip):
    parts = ip.split('.')
    parts[-1] = '1'
    gateway_ip = '.'.join(parts)
    return gateway_ip


def any_ping_received_response(pings: [Ping]) -> bool:
    for ping in pings:
        if ping.received:
            return True
    return False


def check_connectivity(router: Router, ip, interface, count) -> bool:
    pings = router.ping(address=ip, count=count, interface=interface)
    return any_ping_received_response(pings)
