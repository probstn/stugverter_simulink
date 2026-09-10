"""Wait for an ASAM XCP-on-Ethernet target and disconnect cleanly."""

from __future__ import annotations

import argparse
import socket
import struct
import time


def packet(counter: int, payload: bytes) -> bytes:
    return struct.pack("<HH", len(payload), counter & 0xFFFF) + payload


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--target", default="192.168.0.10")
    parser.add_argument("--port", type=int, default=5555)
    parser.add_argument("--local", default="192.168.0.100")
    parser.add_argument("--timeout", type=float, default=15.0)
    args = parser.parse_args()

    started = time.monotonic()
    connect = packet(0, bytes((0xFF, 0x00)))
    disconnect = packet(1, bytes((0xFE,)))

    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as channel:
        channel.bind((args.local, 0))
        channel.settimeout(0.25)
        while time.monotonic() - started < args.timeout:
            channel.sendto(connect, (args.target, args.port))
            try:
                response, _ = channel.recvfrom(2048)
            except TimeoutError:
                continue
            if len(response) >= 5 and response[4] == 0xFF:
                elapsed = time.monotonic() - started
                channel.sendto(disconnect, (args.target, args.port))
                print(f"[+] XCP ready after {elapsed:.3f} s.")
                print(f"XCP_READY_SECONDS={elapsed:.3f}")
                return 0

    print(f"XCP target {args.target}:{args.port} did not answer within {args.timeout:.1f} s.")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
