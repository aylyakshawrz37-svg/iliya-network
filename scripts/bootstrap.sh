#!/usr/bin/env bash
set -euo pipefail
base64 -d scripts/payload/design.b64 > /tmp/iliya-project.tar.gz
mkdir -p .iliya-build
tar -xzf /tmp/iliya-project.tar.gz -C .iliya-build
cp -R .iliya-build/. .
rm -rf .iliya-build /tmp/iliya-project.tar.gz
