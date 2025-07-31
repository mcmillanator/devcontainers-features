
# Create Remote User & Group (create-remote-user)

Create the remoteUser at build time with options and group

## Example Usage

```json
"features": {
    "ghcr.io/mcmillanator/devcontainers-features/create-remote-user:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| REMOTE_GID | Select the GID | string | 1000 |
| REMOTE_GROUP | Select the group name | string | devgrp |
| REMOTE_HOME | Set a default home dir | string | /home/${_REMOTE_USER} |
| REMOTE_SHELL | Select the user shell | string | /usr/bin/bash |
| REMOTE_UID | Select the UID | string | 1000 |



---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/mcmillanator/devcontainers-features/blob/main/src/create-remote-user/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
