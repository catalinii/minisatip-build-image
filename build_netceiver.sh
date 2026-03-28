#!/bin/bash

set -euo pipefail

DIR=${BUILD_DIR:-/tmp}/

cd $DIR/libnetceiver
make install
