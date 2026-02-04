#!/bin/bash

# Get UID/GID of workspace directory
if [ -d "/home/dev/workspace" ]; then
    WORKSPACE_UID=$(stat -c %u /home/dev/workspace)
    WORKSPACE_GID=$(stat -c %g /home/dev/workspace)
    
    # Only modify if different from current dev user
    if [ "$WORKSPACE_UID" != "$(id -u dev)" ]; then
        usermod -u "$WORKSPACE_UID" dev 2>/dev/null
        groupmod -g "$WORKSPACE_GID" dev 2>/dev/null
        chown -R dev:dev /home/dev 2>/dev/null
    fi
fi

# Run as dev user
exec su - dev -c "cd /home/dev/workspace && exec bash"
