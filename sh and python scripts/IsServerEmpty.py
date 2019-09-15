#!/usr/bin/python3

import sys
import re
from valve.rcon import RCON

if len(sys.argv) != 4:
    print("Usage: ./program.py <ip> <port> <rcon password>")
    sys.exit(1)

ip = sys.argv[1]
port = int(sys.argv[2])
password = sys.argv[3]

SERVER_ADDRESS = (ip, port)
PASSWORD = password

try:
    with RCON(SERVER_ADDRESS, PASSWORD) as rcon:
        response = rcon.execute("status")
        response_text = response.body.decode('ascii', 'ignore')
        for line in response_text.splitlines():
            if "players :" in line:
                for words in ['0 humans']:
                    if re.search(r'\b' + words + r'\b', line):
                        print("The server is empty")
                    else:
                        print("The server has players")

except ModuleNotFoundError as e:
	print("ModuleNotFoundError: " + str(e))

except Exception as e:
    print("exception: " + str(e))