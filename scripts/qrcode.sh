#!/usr/bin/env bash

tmp=$(mktemp)
cat public/verifier/qrcode | base64 -d > $tmp && mv $tmp public/verifier/qrcode
