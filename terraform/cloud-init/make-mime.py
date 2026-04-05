#!/usr/bin/env python3
"""
Assembles cloud-init MIME multipart files from a base and role overlay.

Usage:
    python3 make-mime.py <base> <overlay> <output>
"""

import sys
from email.message import Message
from email.mime.multipart import MIMEMultipart


def main():
    if len(sys.argv) != 4:
        print(__doc__)
        sys.exit(1)

    _, base, overlay, output = sys.argv

    msg = MIMEMultipart()
    for path in (base, overlay):
        with open(path) as f:
            part = Message()
            part["Content-Type"] = 'text/cloud-config; charset="utf-8"'
            part["Content-Transfer-Encoding"] = "7bit"
            part.set_payload(f.read())
            msg.attach(part)

    with open(output, "w") as f:
        f.write(msg.as_string())

    print(f"Written: {output}")


if __name__ == "__main__":
    main()
