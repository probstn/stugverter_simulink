"""Wait until the TC387 XCP-on-UDP endpoint is genuinely ready."""
import argparse
import socket
import struct
import sys
import time

def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--target", default="192.168.0.10")
    parser.add_argument("--port", type=int, default=5555)
    parser.add_argument("--local", default="192.168.0.100")
    parser.add_argument("--timeout", type=float, default=15.0)
    args = parser.parse_args()
    started = time.monotonic()
    last_error = "no valid XCP CONNECT response"
    print(f"Waiting for XCP UDP at {args.target}:{args.port} ...")
    while time.monotonic() - started < args.timeout:
        sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        try:
            sock.bind((args.local, 0))
            sock.settimeout(0.25)
            sock.sendto(struct.pack("<HHBB", 2, 0, 0xFF, 0),
                        (args.target, args.port))
            response, _ = sock.recvfrom(2048)
            if len(response) >= 5 and response[4] == 0xFF:
                sock.sendto(struct.pack("<HHB", 1, 1, 0xFE),
                            (args.target, args.port))
                elapsed = time.monotonic() - started
                print(f"[+] XCP ready after {elapsed:.3f} s.")
                print(f"XCP_READY_SECONDS={elapsed:.3f}")
                return 0
        except OSError as exc:
            last_error = str(exc)
        finally:
            sock.close()
        time.sleep(0.1)
    print(f"[!] XCP not ready after {args.timeout:.1f} s: {last_error}", file=sys.stderr)
    return 1

if __name__ == "__main__":
    raise SystemExit(main())
