#!/bin/sh
echo "Complile CoffeScript"

coffee -c -o build src/search.coffee

echo "Copy to dev"
cp build/search.js demo/js/SGAsearch.js
cp build/search.js dist/SGAsearch.js


