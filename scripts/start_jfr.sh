#!/bin/bash

# Starts a JFR recording for the running PetClinic container.
#
# Usage: ./start_jfr.sh <container> [duration] [output]
#   container - name or ID of the Docker container (default: petclinic)
#   duration  - recording length in seconds (default: 60)
#   output    - filename for the JFR recording (default: recording.jfr)

set -euo pipefail

CONTAINER="${1:-petclinic}"
DURATION="${2:-60}"
OUTPUT="${3:-recording.jfr}"

# Determine the Java process ID running PetClinic inside the container
PID=$(docker exec "$CONTAINER" jcmd | awk '/petclinic/ {print $1; exit}')
if [ -z "$PID" ]; then
  echo "Could not find PetClinic process in container $CONTAINER" >&2
  exit 1
fi

# Start JFR recording
docker exec "$CONTAINER" jcmd "$PID" JFR.start duration=${DURATION}s filename=/tmp/$OUTPUT dumponexit=true compress=true

echo "Recording for $DURATION seconds..."
sleep "$DURATION"

# Copy result to host
docker cp "$CONTAINER":/tmp/$OUTPUT "$OUTPUT"
echo "JFR recording saved to $OUTPUT"
