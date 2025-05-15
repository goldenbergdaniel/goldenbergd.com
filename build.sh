#!/bin/bash

rm -rf dist/*

mkdir -p dist
cp -r pages/* assets dist

./generator.bin

if [[ $1 == "run" ]]; then
  echo "Server running on http://127.0.0.1:8080/"
  busybox httpd -h dist -p 8080 -f
fi;
