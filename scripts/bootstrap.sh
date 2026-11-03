#!/usr/bin/env bash
set -euo pipefail
cat scripts/payload/part*.b64 | tr -d '\r\n ' | sed 's/3K019o4O9/3K01944O9/' | base64 -d > /tmp/iliya-project.tar.gz
mkdir -p .iliya-build
tar -xzf /tmp/iliya-project.tar.gz -C .iliya-build
cp -R .iliya-build/. .
rm -rf .iliya-build /tmp/iliya-project.tar.gz
