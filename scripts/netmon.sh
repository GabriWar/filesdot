#!/bin/bash
#find this script path
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#exec python3
python3 "$DIR/netmon/netmon.py" "-wNi 3 --only-new"
