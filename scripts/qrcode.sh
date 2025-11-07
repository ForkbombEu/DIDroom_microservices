#!/usr/bin/env bash

tmp=$(mktemp)
sed 's/^data:image\/png;base64,//' ${1} | base64 -d > ${tmp} && mv ${tmp} ${1}
