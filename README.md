# JDK Performance Benchmarks - Iceberg

This repository contains a helper script for running the [Spring PetClinic](https://github.com/spring-projects/spring-petclinic) application in Docker with different JDK versions. It can be used to measure the impact of JDK upgrades on the application.

## Prerequisites

- Docker installed on the host machine.
- Network access to download Docker images and Maven dependencies.

## Usage

Run `scripts/run_petclinic.sh` and pass the desired JDK version (8, 11 or 23). By default the application is exposed on port `8080`. You can override the port by setting the environment variable `HOST_PORT`.

```bash
# Start PetClinic with JDK 11 (default)
./scripts/run_petclinic.sh

# Start with JDK 8
./scripts/run_petclinic.sh 8

# Start with JDK 23 on port 9090
HOST_PORT=9090 ./scripts/run_petclinic.sh 23
```

When the container is running, access the application at `http://localhost:$HOST_PORT`.
Press `Ctrl+C` to stop and remove the container.

## VisualVM and JMX

`run_petclinic.sh` exposes a JMX port to make it easy to connect tools such as
[VisualVM](https://visualvm.github.io/). The default port is `9010` and can be
changed by setting the `JMX_PORT` environment variable:

```bash
# Run the application and expose JMX on port 9011
JMX_PORT=9011 ./scripts/run_petclinic.sh
```

In VisualVM choose *Add JMX Connection* and connect to `localhost:9011` (or the
port you specified).

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

`start_jfr.sh` automatically launches
[Java Mission Control](https://www.oracle.com/java/technologies/javamissioncontrol.html)
if the `jmc` command is available on your system, opening the recording for
inspection.

## Continuous Integration

The repository includes a GitHub Actions workflow that runs the PetClinic application in a container and executes a small JMeter test plan against it. The results of the JMeter run are uploaded as workflow artifacts.
