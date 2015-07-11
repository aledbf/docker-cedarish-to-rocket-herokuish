#!/usr/bin/env bash

echo "running demo app"

PORT=5000 ./rkt run \
  --insecure-skip-verify \
  --inherit-env \
  rocket-science.io/rocket-herokuish-app:0.0.5
