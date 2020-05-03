#!/usr/bin/env sh

for i in $(seq 1 1000)
do
  rm -- ${i}_*.dat &> /dev/null
done

rm -- *.dat &> /dev/null || true

rm -r -- folder *.iso log.zera parrots pi6.txt &> /dev/null || true
