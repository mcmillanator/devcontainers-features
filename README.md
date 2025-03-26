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
    "ghcr.io/devcontainers/feature-starter/hello:1": {
        "version": "latest",
        "REMOTE_GID": "1000",
        "REMOTE_GROUP": "devgrp",
        "REMOTE_HOME": "/home/dev",
        "REMOTE_SHELL": "/usr/bin/zsh",
        "REMOTE_UID": "1000",
    }
}
```

## Distributing Features

### Publishing

> NOTE: The Distribution spec can be [found here](https://containers.dev/implementors/features-distribution/).
>
> While any registry [implementing the OCI Distribution spec](https://github.com/opencontainers/distribution-spec) can be used, this template will leverage GHCR (GitHub Container Registry) as the backing registry.

Features are meant to be easily sharable units of dev container configuration and installation code.

This repo contains a **GitHub Action** [workflow](.github/workflows/release.yaml) that will publish each Feature to GHCR.

_Allow GitHub Actions to create and approve pull requests_ should be enabled in the repository's `Settings > Actions > General > Workflow permissions` for auto generation of `src/<feature>/README.md` per Feature (which merges any existing `src/<feature>/NOTES.md`).

By default, each Feature will be prefixed with the `<owner/<repo>` namespace. For example, the two Features in this repository can be referenced in a `devcontainer.json` with:

```
ghcr.io/devcontainers/feature-starter/color:1
ghcr.io/devcontainers/feature-starter/hello:1
```

The provided GitHub Action will also publish a third "metadata" package with just the namespace, eg: `ghcr.io/devcontainers/feature-starter`. This contains information useful for tools aiding in Feature discovery.

'`devcontainers/feature-starter`' is known as the feature collection namespace.

### Marking Feature Public

Note that by default, GHCR packages are marked as `private`. To stay within the free tier, Features need to be marked as `public`.

This can be done by navigating to the Feature's "package settings" page in GHCR, and setting the visibility to 'public`. The URL may look something like:

```
https://github.com/users/<owner>/packages/container/<repo>%2F<featureName>/settings
```

<img width="669" alt="image" src="https://user-images.githubusercontent.com/23246594/185244705-232cf86a-bd05-43cb-9c25-07b45b3f4b04.png">

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
