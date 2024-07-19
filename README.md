# Overseer for PIA WireGuard VPN on MikroTik Router

This repository contains a python program for continuously monitor your _[private internet access](https://www.privateinternetaccess.com/)_ VPN, and keep it connected.
PIA disconnects your connection whenever there is inactivity or enough time has passed, a solution is therefore needed to continuously monitor and reestablish a connection whenever the connection is lost.


**The program is specifically designed for MikroTik routers, more specifically RouterOS.**

### Features

- Setup WireGuard interface for PIA VPN
- Add PIA peer to WireGuard interface and keep it updated to maintain connection
- Setup PIA assigned address for WireGuard interface
- Port forwarding through PIA VPN
- Writes forwarded port to file (defined by `STORAGE_FILE` environment variable)

### TODO

- [ ] Consider possibilities for configuring PIA DNS in router.
- [ ] How is the DSTNAT kept up to date in the router when port forwarding?

## Design

The program is setup in such a way, that it creates the WireGuard interface (`/interface/wireguard`) with the specified name, if it does not exist.
If the WireGuard interface exists, it uses that instead.
It does not modify the interface after creation, and only extracts the public key.

The program will ensure that only one peer (`/interface/wireguard/peer`) exist on the interface, and that the peer is setup correctly for communicating with PIA.
If no peer exist, one is created. If multiple peers exist, all are removed and a new one is created.

An address (`/ip/address`) is setup for the WireGuard interface, which is updated whenever PIA assigns a new address to the WireGuard peer.
If no address exist, one is created. If multiple addresses exist, all are removed and a new one is created.

## Limitations

- The program does not currently handle the DNS servers received by PIA.
  You will have to handle DNS setup yourself.
- The API used for communicating with PIA is based on [pia-foss/manual-connections](https://github.com/pia-foss/manual-connections),
  as PIA does not have official support for custom WireGuard config.

## Getting started

To get up and running, copy `.env.template` to `.env` and modify the variables to fit your setup.
When ready, run `cmd.py`.

### Environment variables

- `ROUTER_USERNAME`
    The router username. Example: `admin`.
- `ROUTER_PASSWORD`
    The router password.
- `ROUTER_HOST`
    Where the router can be reached through SSH. Example: `192.168.88.1`.
- `PIA_USERNAME`
    Your PIA username.
- `PIA_PASSWORD`
    Your PIA password.
- `PIA_REGION`
    The PIA region to use. Example: `de_berlin`.
- `VPN_INTERFACE`
    What to name the WireGuard interface in the router. Example: `vpn-pia-berlin-1`.
- `VPN_PING_COUNT`
    The amount of pings to send for checking connectivity.
    Only one ping needs to connect before the connection is considered active.
    Default: `2`.
- `VPN_PING_IP`
    The IP to ping for checking connectivity.
    Default: `1.1.1.1`.
- `VPN_LISTEN_PORT`
    The listening port to set on the WireGuard interface when creating it. The port is not used as _we_ are connecting to PIA, but it is a required field in the router, and it is therefore configurable here, to prevent any clash with another interface using the same port.
    Default: `13231`.
- `VPN_PORTFORWARD_KEEPALIVE_INTERVAL`
    The interval to wait, in minutes, between each keepalive sent to PIA for keeping the port active.
    Default: `15`.
- `VPN_CHECK_CONNECTIVITY_INTERVAL`
    The interval to wait, in minutes, between checking connectivity of the VPN connection and reconfiguring the VPN if needed.
    Default: `5`.
- `STORAGE_FILE`
    Path to a json file that the program uses to store the active connection and communicate with port forwarding program.
    Example: `./storage.json`
- `DEBUG_ROUTER`
    When set to `true`, additional logs are printed to console.
    Specifically, the response for each command sent to the router.
    Default: `false`.
- `DEBUG_PIA`
    When set to `true`, additional logs are printed to console.
    Specifically, the response for each request sent to PIA API.
    Default: `false`.
- `RUN_ONCE`
    When set to `true`, only setup the initial connection and stop immediately afterwards, i.e., the program will not continuously run and send keepalive requests and ensure the connection is active.
    Default: `false`.
- `FORCE_SETUP`
    Setup VPN even if current connection is active and has connectivity.
    Default: `false`.
