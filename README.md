# JDK Performance Benchmarks - Iceberg

This repository contains a helper script for running the [Spring PetClinic](https://github.com/spring-projects/spring-petclinic) application in Docker with different JDK versions. It can be used to measure the impact of JDK upgrades on the application.

## Prerequisites

- Docker installed on the host machine.
- Network access to download Docker images and Maven dependencies.

## Usage

Run `scripts/run_petclinic.sh` and pass the desired JDK version (8, 11, 23 or `graalvm`). By default the application is exposed on port `8080`. You can override the port with `HOST_PORT`. When running in the background the container will be named `petclinic` by default which can be changed with `CONTAINER_NAME`.

```bash
# Start PetClinic with JDK 11 (default)
./scripts/run_petclinic.sh

# Start with JDK 8
./scripts/run_petclinic.sh 8

# Start with JDK 23 on port 9090
HOST_PORT=9090 ./scripts/run_petclinic.sh 23

# Start with GraalVM 23 detached
RUN_BACKGROUND=1 ./scripts/run_petclinic.sh graalvm
```

When the container is running, access the application at `http://localhost:$HOST_PORT`.
Press `Ctrl+C` to stop and remove the container.

## Java Flight Recorder

To capture a JFR recording from a running container, use `scripts/start_jfr.sh`.
Pass the container name or ID, the recording duration in seconds and an optional
output file name:

```bash
# Record 60 seconds from the container named "petclinic" and save to myrun.jfr
./scripts/start_jfr.sh petclinic 60 myrun.jfr
```

If your container is called `petclinic` (as in the CI workflow), the container
argument can be omitted.

## Comparing JDK 23 with GraalVM 23

`scripts/compare_graalvm.sh` automates running the PetClinic benchmark on both
JDK 23 and GraalVM 23. It executes the bundled JMeter test plan while collecting
JFR recordings for each run and places the results under `results/`. If Java
Mission Control (`jmc`) is available on the host, the recordings are opened
automatically.

```bash
./scripts/compare_graalvm.sh
```

## Continuous Integration

The repository includes a GitHub Actions workflow that runs the PetClinic application in a container and executes a small JMeter test plan against it. The results of the JMeter run are uploaded as workflow artifacts.
