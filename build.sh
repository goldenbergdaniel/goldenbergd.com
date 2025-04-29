#!/bin/bash

rm -rf dist

if [[ $1 == "clean" ]]; then exit 0; fi;

rm -rf dist
mkdir dist
cp -r pages/* public dist

bin/esbuild scripts/main.js --bundle --outfile=dist/scripts/main.js --minify --target=es6

if [[ $1 == "run" ]]; then
  busybox httpd -h dist -p 8080 -f
fi;
