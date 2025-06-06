#!/bin/bash

# Runs the Spring PetClinic application inside a Docker container using
# a chosen JDK version. The script downloads the PetClinic source each time
# the container runs.
#
# Usage: ./run_petclinic.sh [JDK_VERSION]
#   JDK_VERSION can be 8, 11, 23 or graalvm (default: 11)
#
# Example:
#   ./run_petclinic.sh 8
#   ./run_petclinic.sh 23
#   ./run_petclinic.sh graalvm

set -euo pipefail

JDK_VERSION="${1:-11}"

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
  graalvm)
    IMAGE="ghcr.io/graalvm/jdk:23"
    ;;
  *)
    echo "Unsupported JDK version: $JDK_VERSION"
    echo "Valid versions: 8, 11, 23, graalvm"
    exit 1
    ;;
esac

# Expose PetClinic on host port 8080
HOST_PORT=${HOST_PORT:-8080}
CONTAINER_NAME=${CONTAINER_NAME:-petclinic}
RUN_BACKGROUND=${RUN_BACKGROUND:-0}

cat <<'SCRIPT' > /tmp/run-petclinic.sh
set -e
apt-get update -y
apt-get install -y git curl >/dev/null

# Clone the Spring PetClinic source
rm -rf spring-petclinic
git clone --depth 1 https://github.com/spring-projects/spring-petclinic.git
cd spring-petclinic

if [ "$JDK_VERSION" = "graalvm" ]; then
  gu install native-image >/dev/null
  ./mvnw -q -Pnative -DskipTests package
  ./target/spring-petclinic
else
  ./mvnw -q package
  java -jar target/*.jar
fi
SCRIPT

chmod +x /tmp/run-petclinic.sh

# Run the container and execute the script inside
if [ "$RUN_BACKGROUND" -eq 1 ]; then
  docker run --rm -d --name "$CONTAINER_NAME" -e JDK_VERSION="$JDK_VERSION" -p ${HOST_PORT}:8080 \
    -v /tmp/run-petclinic.sh:/run-petclinic.sh "$IMAGE" bash /run-petclinic.sh
else
  exec docker run --rm -it --name "$CONTAINER_NAME" -e JDK_VERSION="$JDK_VERSION" -p ${HOST_PORT}:8080 \
    -v /tmp/run-petclinic.sh:/run-petclinic.sh "$IMAGE" bash /run-petclinic.sh
fi

