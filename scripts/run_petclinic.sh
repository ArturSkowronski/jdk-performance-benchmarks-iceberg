#!/bin/bash

# Runs the Spring PetClinic application inside a Docker container using
# a chosen JDK version. The script downloads the PetClinic source each time
# the container runs.
#
# Usage: ./run_petclinic.sh [JDK_VERSION] [MODE]
#   JDK_VERSION can be 8, 11, or 23 (default: 11)
#   MODE can be "appcds" or "crac" to enable AppCDS or CRaC support
#
# Example:
#   ./run_petclinic.sh 8
#   ./run_petclinic.sh 23 appcds
#   ./run_petclinic.sh 23 crac

set -euo pipefail

JDK_VERSION="${1:-11}"
MODE="${2:-}"

if [[ -n "$MODE" && "$MODE" != "appcds" && "$MODE" != "crac" ]]; then
  echo "Unsupported mode: $MODE"
  echo "Valid modes: appcds, crac"
  exit 1
fi

case "$JDK_VERSION" in
  8)
    IMAGE="eclipse-temurin:8-jdk-jammy"
    ;;
  11)
    IMAGE="eclipse-temurin:11-jdk-jammy"
    ;;
  23)
    IMAGE="eclipse-temurin:23-jdk-jammy"
    ;;
  *)
    echo "Unsupported JDK version: $JDK_VERSION"
    echo "Valid versions: 8, 11, 23"
    exit 1
    ;;
esac

if [[ "$MODE" == "crac" ]]; then
  IMAGE="${CRAC_IMAGE:-crac-jdk:17}"
fi

# Expose PetClinic on host port 8080
HOST_PORT=${HOST_PORT:-8080}

cat <<SCRIPT > /tmp/run-petclinic.sh
set -e
apt-get update
apt-get install -y git curl

# Clone the Spring PetClinic source
rm -rf spring-petclinic
git clone --depth 1 https://github.com/spring-projects/spring-petclinic.git
cd spring-petclinic

# Build and run using the Maven wrapper
./mvnw -q package

MODE="$MODE"
if [ "\$MODE" = "appcds" ]; then
  java -XX:ArchiveClassesAtExit=/tmp/petclinic.jsa -jar target/*.jar &
  PID=\$!
  sleep 30
  kill \$PID || true
  java -XX:SharedArchiveFile=/tmp/petclinic.jsa -jar target/*.jar
elif [ "\$MODE" = "crac" ]; then
  CHECKPOINT_DIR=/tmp/crac-checkpoint
  mkdir -p \$CHECKPOINT_DIR
  java -XX:CRaCCheckpointTo=\$CHECKPOINT_DIR -jar target/*.jar &
  PID=\$!
  sleep 30
  jcmd \$PID JDK.checkpoint
  java -XX:CRaCRestoreFrom=\$CHECKPOINT_DIR -jar target/*.jar
else
  java -jar target/*.jar
fi
SCRIPT

chmod +x /tmp/run-petclinic.sh

# Run the container and execute the script inside
exec docker run --rm -it -p ${HOST_PORT}:8080 \
  -v /tmp/run-petclinic.sh:/run-petclinic.sh \
  -e MODE="$MODE" \
  "$IMAGE" bash /run-petclinic.sh

