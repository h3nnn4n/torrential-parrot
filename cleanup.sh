#!/usr/bin/env sh

for i in `seq 99 1`
do
  rm *_$i*_*.dat &> /dev/null
done

rm *.dat &> /dev/null || true
