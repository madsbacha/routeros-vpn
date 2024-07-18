class Ping:
    def __init__(self, seq, host, size, ttl, time, sent, received, packet_loss, min_rtt, avg_rtt, max_rtt):
        self.seq = seq
        self.host = host
        self.size = size
        self.ttl = ttl
        self.time = time
        self.sent = sent
        self.received = received
        self.packet_loss = packet_loss
        self.min_rtt = min_rtt
        self.avg_rtt = avg_rtt
        self.max_rtt = max_rtt

    @staticmethod
    def from_dict(args):
        return Ping(
            seq=args.get("seq"),
            host=args.get("host"),
            size=args.get("size"),
            ttl=args.get("ttl"),
            time=args.get("time"),
            sent=args.get("sent") == '1',
            received=args.get("received") == '1',
            packet_loss=args.get("packet-loss"),
            min_rtt=args.get("min-rtt"),
            avg_rtt=args.get("avg-rtt"),
            max_rtt=args.get("max-rtt"),
        )
