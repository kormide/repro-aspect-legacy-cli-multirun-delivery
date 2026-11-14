#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

bazel build //:deliver_all

# Mimic what delivery manifest step runs when selective delivery is enabled (only_on_change = true).
bazel outputs //:deliver_all ExecutableHash
