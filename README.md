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
