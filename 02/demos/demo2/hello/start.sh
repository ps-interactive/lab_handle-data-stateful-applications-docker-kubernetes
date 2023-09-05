#!/bin/sh

echo "Contents: $(cat /hello.txt)"

trap : TERM INT; (while true; do sleep 1000; done) & wait
