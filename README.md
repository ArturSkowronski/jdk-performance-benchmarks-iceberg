# JDK Performance Benchmarks - Iceberg

This repository contains a helper script for running the [Spring PetClinic](https://github.com/spring-projects/spring-petclinic) application in Docker with different JDK versions. It can be used to measure the impact of JDK upgrades on the application.

## Prerequisites

- Docker installed on the host machine.
- Network access to download Docker images and Maven dependencies.

## Usage

Run `scripts/run_petclinic.sh` and pass the desired JDK version (8, 11 or 23). A second optional argument enables extra features: `appcds` turns on Application Class-Data Sharing and `crac` starts the application using a CRaC-enabled JDK. By default the application is exposed on port `8080`. You can override the port by setting the environment variable `HOST_PORT`.

```bash
# Start PetClinic with JDK 11 (default)
./scripts/run_petclinic.sh

# Start with JDK 8
./scripts/run_petclinic.sh 8

# Start with JDK 23 on port 9090
HOST_PORT=9090 ./scripts/run_petclinic.sh 23

# Start with AppCDS enabled
./scripts/run_petclinic.sh 23 appcds

# Start using a CRaC-enabled JDK
./scripts/run_petclinic.sh 23 crac
```

The `appcds` option generates a class data sharing archive on first startup and
then runs the application using that archive.

When the container is running, access the application at `http://localhost:$HOST_PORT`.
Press `Ctrl+C` to stop and remove the container.

When running in `crac` mode the script uses a CRaC-enabled JDK image. Set the
`CRAC_IMAGE` environment variable to override the Docker image name if needed.

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

## Continuous Integration

The repository includes a GitHub Actions workflow that runs the PetClinic application in a container and executes a small JMeter test plan against it. The results of the JMeter run are uploaded as workflow artifacts.
