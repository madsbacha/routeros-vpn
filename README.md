# Private Internet Access WireGuard VPN on MikroTik Router

This repository contains a RouterOS script for creating and maintaining a _[private internet access](https://www.privateinternetaccess.com/)_ VPN, by configuring the necessary WireGuard interface and peer, address, and handling of reconfiguring the interface when the connection is lost, because of inactivity, thus reestablishing the connection to always maintain a working configuration.

> [!IMPORTANT]  
> This repository is still in active development. That being said, the code from the *main* branch is actively being used, and should therefore be in a working state.

This script is verified to work on RouterOS version 7.16.

### Features

- Setup WireGuard interface for PIA VPN
- Add PIA peer to WireGuard interface
- Reconfigure WireGuard interface if connection is lost
- Setup PIA assigned address for the WireGuard interface
- Automatically setup src masquerading for outgoing traffic on the VPN interface 
- Verifies TLS certificate of the PIA servers against their self-signed CA certificate

### TODO

- [ ] Port forwarding through PIA VPN.
- [ ] Consider possibilities for configuring PIA DNS in router.

## Design

The script is setup to ensure that the specified WireGuard interface exists, i.e., it is created if it does not exist, and otherwise uses the existing one with that name.
It does not modify the interface after creation, and only extracts the public key.

The program will ensure that only one peer exist on the interface, and that the peer is setup correctly for communicating with PIA.
If no peer exist, one is created and any excess peers not needed for the connection is removed.

An address is setup for the WireGuard interface, which is updated whenever PIA assigns a new address to the WireGuard peer.
If no address exist, one is created and any excess address configuration for the interface is removed.

## Limitations

- The program does not currently handle the DNS servers received by PIA.
  You will have to handle DNS setup yourself.
- The API used for communicating with PIA is based on [pia-foss/manual-connections](https://github.com/pia-foss/manual-connections),
  as PIA does not have official support for custom WireGuard config.

## Getting Started

> [!NOTE]  
> The following "Getting Started" section is a temporary solution until the script is finished and a more elegant setup is created.

To get started, you need to setup the script `vpn.rsc` in your router, by going to *System > Scripts*, and create a new script with the *source* field set to the contents of `vpn.rsc`. The script only need the `read`, `write`, and `test` policies, and you can therefore disable the rest.

When inserted, edit the bottom of the file and change the parameters by filling in your PIA username and password, and possibly adjusting the PIA region and the interface name accordingly.
If your password contain the characters `?` or `$`, you need to escape them with a backslash; `\?` and `\$`. See the [Scripting Wiki page](https://wiki.mikrotik.com/wiki/Manual:Scripting#:~:text=value%20is%20assigned%3B-,Constant%20Escape%20Sequences,-Following%20escape%20sequences) for more info. Additionally, avoid instances of `$[]` and `$()` as they are used for [inserting expressions inside strings](https://wiki.mikrotik.com/wiki/Manual:Scripting#:~:text=By%20using%20%24%5B%5D%20and%20%24()%20in%20string%20it%20is%20possible%20to%20add%20expressions%20inside%20strings).

Lastly, setup a schedule to run the script every 15 minutes. This ensures the connection is checked every 15 minutes and reconfigured if the connection is down. Replace `vpn-pia-berlin-1` in the following with what you named the above script.
```
/system/scheduler/add name="vpn-pia-berlin-1" interval=15m start-time=startup on-event="/system/script/run vpn-pia-berlin-1;";
```

> [!IMPORTANT]
> The script automatically creates the specified interface if it does not exist, and ensures a working VPN connection is setup through the WireGuard interface. Hereafter, it is your responsibility to configure the router to actually route any desired traffic through the interface. See section [Routing traffic through a VPN Interface](#routing-traffic-through-a-vpn-interface) for further details.

### Parameters

- `interface`
    The name which the script uses for the WireGuard interface. The interface is created if none exist.
    Example: `vpn-pia-berlin-1`.
- `region`
    The PIA server region to connect to.
    Example: `de_berlin`.
- `pia-username`
    Your PIA username.
- `pia-password`
    Your PIA password.
- `ping-address`
    The address used for checking connectivity through the VPN connection. The address is pinged once to check connectivity.
    Default: `1.1.1.1`.
- `servers-file-path`
    Specifies a path for where to cache the PIA servers to.
    Default: `pia-servers.txt`.
- `pia-servers-ttl`
    Specifies the duration of which the `servers-file-path` is kept before updated. If encountering problems connecting to PIA servers, try setting this to a lower value.
    Default: `24h`.
- `masquerade`
    Specifies whether to automatically create a src masquerade rule in your firewall.
    Default: `true`.
- `verify-pia-certificate`
    Specifies whether to verify the TLS certificate of the PIA servers.
    Default: `true`.
- `install-pia-certificate`
    Specifies whether to automatically install the PIA CA certificate for verifying PIA servers.
    Default: `true`.

## Routing traffic through a VPN Interface

The script only serves to keep the WireGuard interface up and running.
This section thus serves to guide you through configuring RouterOS to route traffic through
the WireGuard interface.

There are several approaches to routing traffic through the interface:
- [Firewall mangle rules](https://help.mikrotik.com/docs/spaces/ROS/pages/48660587/Mangle)
- [Routing rules](https://help.mikrotik.com/docs/spaces/ROS/pages/59965508/Policy+Routing#PolicyRouting-RoutingRules)


### Routing using Firewall Mangle

The following config uses firewall mangle rules to route specific websites (in this case
[myip.wtf](https://myip.wtf/)) through the VPN interface.

The configuration:
1. Sets up a routing table called `vpn-routing` for all the VPN traffic
2. Adds a default route and a blackhole to the VPN routing table.
3. Creates an address list for local addresses, such that the mangle rules doesn't affect
   connections meant for the LAN.
4. Creates and adds an example website `myip.wtf` to the address list
   `route-through-pia-vpn`. The websites in this list will be routed through the VPN.
5. Sets up mangle rules that
   1. marks connections that are directed towards websites in the `route-through-pia-vpn`
   address list.
   2. moves marked connections to the `vpn-routing` routing table.

If using the following config, replace `vpn-pia-berlin-1` with whatever your VPN interface
is named.

```routeros
/routing table
add disabled=no fib name=vpn-routing

/ip route
add disabled=no distance=1 dst-address=0.0.0.0/0 gateway=vpn-pia-berlin-1 \
    routing-table=vpn-routing scope=30 suppress-hw-offload=no target-scope=10
add blackhole comment="VPN blackhole" disabled=no distance=100 dst-address=\
    0.0.0.0/0 gateway="" routing-table=vpn-routing suppress-hw-offload=no

/ip firewall address-list
add address=10.0.0.0/8 list=rfc1918
add address=172.16.0.0/12 list=rfc1918
add address=192.168.0.0/16 list=rfc1918

/ip firewall address-list
add address=myip.wtf list=route-through-pia-vpn

/ip firewall mangle
add action=mark-connection chain=prerouting comment=\
    "Mark connections for VPN" dst-address-list=route-through-pia-vpn \
    new-connection-mark=pia-vpn-connection
add action=mark-routing chain=prerouting comment="Move to vpn-routing" \
    connection-mark=pia-vpn-connection dst-address-list=!rfc1918 \
    new-routing-mark=vpn-routing
```

