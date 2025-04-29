#!/bin/bash

rm -rf dist
mkdir dist
cp -r pages/* dist
cp -r public dist

bin/esbuild scripts/main.js --bundle --outfile=dist/scripts/main.js --minify --target=es6

if [[ $1 == "run" ]]; then
  busybox httpd -f -p 8080 -h dist
fi;
