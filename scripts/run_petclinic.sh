#!/usr/bin/env bash
#
# Runs the Spring PetClinic demo in Docker.
#
# Usage:  ./run_petclinic.sh [JDK_VERSION] [MODE]
#   JDK_VERSION : 8 | 11 | 23 | graalvm      (default: 11)
#   MODE        : appcds | crac              (optional)
#
# Examples
#   ./run_petclinic.sh 8                 # plain JVM on Temurin 8
#   ./run_petclinic.sh 23 appcds         # Temurin 23 with AppCDS
#   ./run_petclinic.sh 23 crac           # CRaC-enabled JDK image
#   ./run_petclinic.sh graalvm           # GraalVM native-image build
#

set -euo pipefail

JDK_VERSION="${1:-11}"
MODE="${2:-}"

# Validate MODE, if provided
if [[ -n "$MODE" && "$MODE" != "appcds" && "$MODE" != "crac" ]]; then
  echo "Unsupported mode: $MODE"
  echo "Valid modes: appcds, crac"
  exit 1
fi

# Default ports and flags (overridable via env vars)
HOST_PORT="${HOST_PORT:-8080}"
JMX_PORT="${JMX_PORT:-9010}"
CONTAINER_NAME="${CONTAINER_NAME:-petclinic}"
RUN_BACKGROUND="${RUN_BACKGROUND:-0}"

# Select base image
case "$JDK_VERSION" in
  8)      IMAGE="eclipse-temurin:8-jdk-jammy" ;;
  11)     IMAGE="eclipse-temurin:11-jdk-jammy" ;;
  23)     IMAGE="eclipse-temurin:23-jdk" ;;
  graalvm) IMAGE="ghcr.io/graalvm/jdk:23" ;;
  *)
    echo "Unsupported JDK version: $JDK_VERSION"
    echo "Valid versions: 8, 11, 23, graalvm"
    exit 1
    ;;
esac

# If CRaC mode selected, allow custom CRaC-enabled image
if [[ "$MODE" == "crac" ]]; then
  IMAGE="${CRAC_IMAGE:-ghcr.io/crac/openjdk17:latest}"
fi

# Create the script that will run *inside* the container
cat <<'SCRIPT' >/tmp/run-petclinic.sh
#!/usr/bin/env bash
set -e

# Expect env vars:  MODE JDK_VERSION JMX_PORT
apt-get update -y >/dev/null
apt-get install -y git curl >/dev/null

rm -rf spring-petclinic
git clone --depth 1 https://github.com/spring-projects/spring-petclinic.git
cd spring-petclinic

# -------- GraalVM native build --------
if [[ "$JDK_VERSION" == "graalvm" ]]; then
  gu install native-image >/dev/null
  ./mvnw -q -Pnative -DskipTests package
  ./target/spring-petclinic
  exit 0
fi

# -------- Standard JVM build --------
./mvnw -q package

# Common JMX options (ignored for native build)
export JAVA_TOOL_OPTIONS="$JAVA_TOOL_OPTIONS \
  -Dcom.sun.management.jmxremote \
  -Dcom.sun.management.jmxremote.port=$JMX_PORT \
  -Dcom.sun.management.jmxremote.rmi.port=$JMX_PORT \
  -Dcom.sun.management.jmxremote.local.only=false \
  -Dcom.sun.management.jmxremote.ssl=false \
  -Dcom.sun.management.jmxremote.authenticate=false \
  -Djava.rmi.server.hostname=localhost"

JAR_FILE=$(ls target/*.jar | head -n1)

case "$MODE" in
  appcds)
    # First run to generate the archive
    java -XX:ArchiveClassesAtExit=/tmp/petclinic.jsa -jar "$JAR_FILE" &
    PID=$!
    sleep 30 && kill "$PID" 2>/dev/null || true
    # Second run using the shared archive
    exec java -XX:SharedArchiveFile=/tmp/petclinic.jsa -jar "$JAR_FILE"
    ;;
  crac)
    CHECKPOINT_DIR=/tmp/crac-checkpoint
    mkdir -p "$CHECKPOINT_DIR"
    java -XX:CRaCCheckpointTo="$CHECKPOINT_DIR" -jar "$JAR_FILE" &
    PID=$!
    sleep 30
    jcmd "$PID" JDK.checkpoint
    exec java -XX:CRaCRestoreFrom="$CHECKPOINT_DIR" -jar "$JAR_FILE"
    ;;
  *)
    exec java -jar "$JAR_FILE"
    ;;
esac
SCRIPT

chmod +x /tmp/run-petclinic.sh

# -------- Docker run --------
DOCKER_ARGS=(
  --rm
  --name "$CONTAINER_NAME"
  -e JDK_VERSION="$JDK_VERSION"
  -e MODE="$MODE"
  -e JMX_PORT="$JMX_PORT"
  -p "${HOST_PORT}:8080"
  -p "${JMX_PORT}:${JMX_PORT}"
  -v /tmp/run-petclinic.sh:/run-petclinic.sh
  "$IMAGE"
  bash /run-petclinic.sh
)

if [[ "$RUN_BACKGROUND" -eq 1 ]]; then
  docker run -d "${DOCKER_ARGS[@]}"
  echo "PetClinic is starting in background container: $CONTAINER_NAME"
else
  exec docker run -it "${DOCKER_ARGS[@]}"
fi