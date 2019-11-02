#!/bin/bash
maxProcs=20
port=1337

while true; do
    procs=$(jobs | wc -l)
    echo "starting $(($maxProcs - $procs))"
    for i in `seq 1 $(($maxProcs - $procs))`; do
        echo "starting proc"
        python3 solvePadding.py $port >/dev/null &
    done
    wait -n
done
