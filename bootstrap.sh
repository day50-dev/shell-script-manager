#!/usr/bin/env bash
# ursh bootstrap
# Usage: curl -sSL day50.dev/ursh | bash
#
# This tiny script fetches install.sh from GitHub and runs it.
# The real install logic lives in install.sh in the repo and can be
# updated there without ever redeploying this file.
set -e
curl -fsSL https://raw.githubusercontent.com/day50-dev/ursh/main/install.sh | bash
