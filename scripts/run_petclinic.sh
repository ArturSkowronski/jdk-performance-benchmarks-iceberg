#!/bin/bash

# Runs the Spring PetClinic application inside a Docker container using
# a chosen JDK version. The script downloads the PetClinic source each time
# the container runs.
#
# Usage: ./run_petclinic.sh [JDK_VERSION]
#   JDK_VERSION can be 8, 11, or 23 (default: 11)
#
# Example:
#   ./run_petclinic.sh 8
#   ./run_petclinic.sh 23

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
  *)
    echo "Unsupported JDK version: $JDK_VERSION"
    echo "Valid versions: 8, 11, 23"
    exit 1
    ;;
esac

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
java -jar target/*.jar
SCRIPT

chmod +x /tmp/run-petclinic.sh

# Run the container and execute the script inside
exec docker run --rm -it -p ${HOST_PORT}:8080 -v /tmp/run-petclinic.sh:/run-petclinic.sh "$IMAGE" bash /run-petclinic.sh

