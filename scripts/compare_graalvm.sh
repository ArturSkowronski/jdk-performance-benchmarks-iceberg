#!/bin/bash

# Compare Spring PetClinic running on JDK 23 and GraalVM 23.
# Runs a JMeter test plan against each instance while recording
# Java Flight Recorder data. Results are stored in the "results" directory.

set -euo pipefail

DURATION=${DURATION:-60}
RESULTS_DIR=${RESULTS_DIR:-results}
HOST_PORT=${HOST_PORT:-8080}
CONTAINER_NAME=petclinic

mkdir -p "$RESULTS_DIR"

wait_for_petclinic() {
  for i in {1..30}; do
    if curl -s "http://localhost:${HOST_PORT}" >/dev/null; then
      return 0
    fi
    sleep 2
  done
  echo "PetClinic did not start in time" >&2
  exit 1
}

run_benchmark() {
  local mode="$1" jfr_file="$2" result_file="$3"

  echo "Starting PetClinic using $mode..."
  if [ "$mode" = "graalvm" ]; then
    RUN_BACKGROUND=1 CONTAINER_NAME="$CONTAINER_NAME" ./scripts/run_petclinic.sh graalvm > /tmp/petclinic.log 2>&1 &
  else
    RUN_BACKGROUND=1 CONTAINER_NAME="$CONTAINER_NAME" ./scripts/run_petclinic.sh 23 > /tmp/petclinic.log 2>&1 &
  fi
  pid=$!

  wait_for_petclinic

  ./scripts/start_jfr.sh "$CONTAINER_NAME" "$DURATION" "$RESULTS_DIR/$jfr_file" &
  jfr_pid=$!

  docker run --rm -v "$(pwd)/jmeter:/tests" justb4/jmeter:5.5 \
    -n -t /tests/petclinic.jmx -l "$RESULTS_DIR/$result_file"

  wait "$jfr_pid"
  docker rm -f "$CONTAINER_NAME" >/dev/null
  wait "$pid" || true
}

run_benchmark jdk23 jdk23.jfr jdk23.jtl
run_benchmark graalvm graalvm.jfr graalvm.jtl

cat <<MSG
JFR recordings created in $RESULTS_DIR
  JDK 23   -> $RESULTS_DIR/jdk23.jfr
  GraalVM  -> $RESULTS_DIR/graalvm.jfr
MSG

if command -v jmc >/dev/null; then
  jmc "$RESULTS_DIR/jdk23.jfr" "$RESULTS_DIR/graalvm.jfr" &
else
  echo "To open the recordings in JMC run:"
  echo "  jmc $RESULTS_DIR/jdk23.jfr $RESULTS_DIR/graalvm.jfr"
fi
