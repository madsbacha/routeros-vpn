class Address:
    def __init__(self, cidr, interface, network=None, comment=None, idx=None):
        self.cidr = cidr
        self.network = network
        self.interface = interface
        self.comment = comment
        self.idx = idx

        self.cidr = f"{self.cidr}/32" if "/" not in self.cidr else self.cidr

    def to_dict(self):
        args = {
            "address": self.cidr,
            "interface": self.interface,
        }
        if self.network is not None:
            args["network"] = self.network
        if self.comment is not None:
            args["comment"] = self.comment
        return args

    @staticmethod
    def from_dict(args):
        return Address(
            cidr=args.get("address"),
            interface=args.get("interface"),
            network=args.get("network"),
            comment=args.get("comment"),
            idx=args.get(".id"),
        )
