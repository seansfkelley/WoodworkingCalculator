#!/usr/bin/env bash

set -euo pipefail

make -q build

./main "$@"
