#!/usr/bin/env bash

program=$(<program)
intcode=(${program//,/ })

if [[ $# -ne 1 ]]; then
    echo "usage: ./part2 number to find"
    exit 2
fi

for i in {0..99}
do
    for j in {0..99}
    do
        intcode[1]=$i
        intcode[2]=$j
        echo $( IFS=$','; echo "${intcode[*]}" ) > program
        output=$(./compiler | tr '\0' '\n')
        echo "try: $i/$j = $output"
        if [ "$output" == "$1" ]
            then
                echo "FOUND!"
                break 2
        fi
    done
done