#!/bin/sh

for f in `cat manifest.txt`
do
  echo $f
  cp ../../$f $f
done

