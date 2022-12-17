#!/bin/bash

databasecontainers=(
    # ------- Database Containers -------
    MariaDB
)
applicationcontainers=(
    # ---------- App Containers ----------
    Frigate
    HomeAssistant
    Tailscale
    PterodactylPanel
    PterodactylDaemon
    DuckDNS
    Authelia
    NginxProxyManager
)
# -------- Seconds to delay startup
delay=600
delayedcontainers=(
    # ---- Delayed Startup Containers ----
    Machinaris
)
gamecontainers=(
    # ----------- Game Servers -----------
    # BeamMP
    491bee12-f93a-4607-831f-32b0d98c4250
    # Minecraft - Survival
    24ae2053-87b4-4104-a071-d36197360b3b
)

commands1() {
    # Commands to run before stopping containers
}
commands2() {
    # Commands to run before starting containers back up
}
commands3() {
    # Commands to run after starting containers back up
}

# ------ Ignore stuff below this line, this is the script ------
shutdowncon() {
    echo "Stopping applications"
    for d in "${applicationcontainers[@]}"; do
        docker stop "$d"
    done
    for d in "${delayedcontainers[@]}"; do
        docker stop "$d"
    done
    echo "Stopping game servers"
    for d in "${gamecontainers[@]}"; do
        docker stop "$d"
    done
    echo "Stopping databases"
    for d in "${databasecontainers[@]}"; do
        docker stop "$d"
    done
}
killcon() {
    echo "Killing containers that took longer than 60 seconds to shut down"
    for d in "${applicationcontainers[@]}"; do
        docker kill "$d"
    done
    for d in "${delayedcontainers[@]}"; do
        docker kill "$d"
    done
    for d in "${gamecontainers[@]}"; do
        docker kill "$d"
    done
}
startupcon() {
    echo "Starting databases"
    for d in "${databasecontainers[@]}"; do
        docker start "$d"
    done
    sleep 10
    echo "Starting applications"
    for d in "${applicationcontainers[@]}"; do
        docker start "$d"
    done
    echo "Starting game servers"
    for d in "${gamecontainers[@]}"; do
        docker start "$d"
    done
    sleep $delay
    for d in "${delayedcontainers[@]}"; do
        docker start "$d"
    done
}
init() {
    commands1
    echo "Running container automations"
    shutdowncon
    sleep 60
    killcon
    commands2
    sleep 1
    startupcon
    commands3
    echo "Done running container automations"
}
init
