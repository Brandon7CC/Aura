#!/bin/bash

# Usage: ./deploy.sh -u [user] -k [ssh_key] -f [file] -d [remote_directory] -h [hostname]

# Default values
USER="root"
SSH_KEY="$HOME/.ssh/ipad-root-ssh"
FILE="$HOME/Downloads/aura"
REMOTE_DIR="/tmp/var/db/com.apple.xpc.roleaccountd.staging/"
HOST="BrandontonsiPad"

# Parse command line options
while getopts u:k:f:d:h: flag
do
    case "${flag}" in
        u) USER=${OPTARG};;
        k) SSH_KEY=${OPTARG};;
        f) FILE=${OPTARG};;
        d) REMOTE_DIR=${OPTARG};;
        h) HOST=${OPTARG};;
    esac
done

# Commands to create directory, transfer file, set permissions, and execute binary
ssh -i "${SSH_KEY}" "${USER}@${HOST}" "mkdir -p ${REMOTE_DIR}" &&
scp -i "${SSH_KEY}" "${FILE}" "${USER}@${HOST}:${REMOTE_DIR}" &&
ssh -i "${SSH_KEY}" "${USER}@${HOST}" "chmod +x ${REMOTE_DIR}/$(basename ${FILE}) && cd ${REMOTE_DIR} && ./$(basename ${FILE})"

if [ $? -eq 0 ]; then
    echo "Deployment and execution successful."
else
    echo "An error occurred during the deployment."
fi

