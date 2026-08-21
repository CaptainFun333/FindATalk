#!/bin/bash
cd "/Users/smoothop/Downloads/FindATalk files/docs" || exit 1
exec python3 -m http.server 8934 --bind 127.0.0.1
