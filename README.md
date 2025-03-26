# Dev Container Features: Self Authoring Template

This repository contains a _collection_ of Features - `create user and group`.
Each sub-section below shows a sample `devcontainer.json` alongside example
usage of the Feature.

## `create remote user`

create-remote-user allows you to create or replace a user in the container at build.
If the username or id already exists it will be deleted and replaced to ensure
all value are set.

```json
"features": {
    "ghcr.io/mcmillanator/devcontainers-features/create-remote-user:1": {
        "version": "latest",
        "REMOTE_GID": "1000",
        "REMOTE_GROUP": "devgrp",
        "REMOTE_HOME": "/home/dev",
        "REMOTE_SHELL": "/usr/bin/zsh",
        "REMOTE_UID": "1000",
    }
}
```

### Adding Features to the Index

If you'd like your Features to appear in our [public index](https://containers.dev/features) so that other community members can find them, you can do the following:

- Go to [github.com/devcontainers/devcontainers.github.io](https://github.com/devcontainers/devcontainers.github.io)
  - This is the GitHub repo backing the [containers.dev](https://containers.dev/) spec site
- Open a PR to modify the [collection-index.yml](https://github.com/devcontainers/devcontainers.github.io/blob/gh-pages/_data/collection-index.yml) file

This index is from where [supporting tools](https://containers.dev/supporting) like [VS Code Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) and [GitHub Codespaces](https://github.com/features/codespaces) surface Features for their dev container creation UI.

#### Using private Features in Codespaces

For any Features hosted in GHCR that are kept private, the `GITHUB_TOKEN` access token in your environment will need to have `package:read` and `contents:read` for the associated repository.

Many implementing tools use a broadly scoped access token and will work automatically. GitHub Codespaces uses repo-scoped tokens, and therefore you'll need to add the permissions in `devcontainer.json`

An example `devcontainer.json` can be found below.

```jsonc
{
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "ghcr.io/my-org/private-features/hello:1": {
      "greeting": "Hello"
    }
  },
  "customizations": {
    "codespaces": {
      "repositories": {
        "my-org/private-features": {
          "permissions": {
            "packages": "read",
            "contents": "read"
          }
        }
      }
    }
  }
}
```
