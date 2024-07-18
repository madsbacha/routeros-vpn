class Peer:
    def __init__(self, interface, address, port, public_key, idx=None, name=None, allowed_addresses=None, persistent_keepalive=None, comment=None):
        self.interface = interface
        self.address = address
        self.port = port
        self.public_key = public_key
        self.idx = idx
        self.name = name
        self.allowed_addresses = allowed_addresses
        self.persistent_keepalive = persistent_keepalive
        self.comment = comment

        if self.allowed_addresses is None:
            self.allowed_addresses = "0.0.0.0/0"
        if self.persistent_keepalive is None:
            self.persistent_keepalive = "25s"

    def to_dict(self):
        args = {
            "interface": self.interface,
            "endpoint-address": self.address,
            "endpoint-port": self.port,
            "public-key": self.public_key,
            "allowed-address": self.allowed_addresses,
            "persistent-keepalive": self.persistent_keepalive,
        }
        if self.name is not None:
            args["name"] = self.name
        if self.comment is not None:
            args["comment"] = self.comment
        return args

    @staticmethod
    def from_dict(args):
        return Peer(
            idx=args.get(".id"),
            interface=args.get("interface"),
            address=args.get("endpoint-address"),
            port=args.get("endpoint-port"),
            public_key=args.get("public-key"),
            name=args.get("name"),
            allowed_addresses=args.get("allowed-addresses"),
            persistent_keepalive=args.get("persistent-keepalive"),
            comment=args.get("comment"),
        )
