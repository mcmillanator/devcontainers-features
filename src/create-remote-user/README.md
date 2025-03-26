# Create Remote User & Group (create-remote-user)

A feature for creating custom user and group at build

## Example Usage

```json
"features": {
    "ghcr.io/devcontainers/feature-starter/hello:1": {
        "version": "latest"
        "REMOTE_GID": "1000",
        "REMOTE_GROUP": "stan",
        "REMOTE_SHELL": "/usr/bin/zsh",
        "REMOTE_UID": "1000"
    }
}
```

## Options

| Options Id   | Description          | Type   | Default Value |
| ------------ | -------------------- | ------ | ------------- |
| REMOTE_GID   | Set the GID          | string | 1000          |
| REMOTE_GROUP | Set the group name   | string | devgrp        |
| REMOTE_SHELL | Set the remote shell | string | /bin/bash     |
| REMOTE_UID   | Set the UID          | string | 1000          |

---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/devcontainers/feature-starter/blob/main/src/hello/devcontainer-feature.json). Add additional notes to a `NOTES.md`._
