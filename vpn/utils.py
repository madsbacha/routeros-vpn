from vpn import VpnContext
from pia.wireguard import WireGuardConnection
from router.domain import Address
from router.domain.wireguard import Peer
from router.utils import check_connectivity, gateway_from_ip


def setup_address(ctx: VpnContext, pia_wg_connection: WireGuardConnection):
    new_router_address = Address(
        cidr=pia_wg_connection.address,
        interface=ctx.config.vpn_interface,
        network=pia_wg_connection.gateway
    )
    router_addresses = ctx.router.get_addresses(ctx.config.vpn_interface)
    if len(router_addresses) != 1:
        if len(router_addresses) > 1:
            ctx.router.remove_address_from_interface(ctx.config.vpn_interface)
        ctx.router.create_address(new_router_address)
    else:
        ctx.router.update_address(router_addresses[0].idx, new_router_address)


def setup_peer(ctx: VpnContext, pia_wg_connection: WireGuardConnection):
    new_peer = Peer(
        interface=ctx.config.vpn_interface,
        address=pia_wg_connection.endpoint_address,
        port=pia_wg_connection.endpoint_port,
        public_key=pia_wg_connection.peer_public_key,
        name=f"{ctx.config.vpn_interface}-peer"
    )
    peers = ctx.router.get_wireguard_peers(ctx.config.vpn_interface)
    if len(peers) == 1:
        ctx.router.update_wireguard_peer(peers[0].idx, new_peer)
    else:
        if len(peers) > 1:
            ctx.router.clear_wireguard_peers(ctx.config.vpn_interface)
        ctx.router.create_wireguard_peer(new_peer)


def setup_interface(ctx):
    if not ctx.router.has_wireguard_interface(ctx.config.vpn_interface):
        ctx.router.create_wireguard_interface(ctx.config.vpn_interface, ctx.config.vpn_listen_port)
    public_key = ctx.router.get_wireguard_interface_public_key(ctx.config.vpn_interface)
    return public_key


def is_vpn_running(ctx: VpnContext):
    has_wireguard_interface = ctx.router.has_wireguard_interface(ctx.config.vpn_interface)
    can_connect = check_connectivity(ctx.router, ip=ctx.config.vpn_ping_ip, count=ctx.config.vpn_ping_count, interface=ctx.config.vpn_interface)
    return has_wireguard_interface and can_connect


def setup_vpn(ctx: VpnContext):
    print("Setting up VPN.")
    public_key = setup_interface(ctx)
    pia_wireguard_connection = ctx.pia.create_wireguard_config(ctx.config.pia_region, public_key)
    setup_address(ctx, pia_wireguard_connection)
    setup_peer(ctx, pia_wireguard_connection)

    # TODO: Route DNS