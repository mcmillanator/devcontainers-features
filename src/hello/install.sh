#!/bin/bash
set -e

echo "Activating feature 'create-remote-user'"
DEPENDENCIES=(adduser passwd)
USER_OPTS=""
GROUP_OPTS=""

# Function to detect the package manager
detect_package_manager() {
  if command -v apt-get >/dev/null 2>&1; then
    echo "apt-get"
  elif command -v dnf >/dev/null 2>&1; then
    echo "dnf"
  elif command -v yum >/dev/null 2>&1; then
    echo "yum"
  elif command -v pacman >/dev/null 2>&1; then
    echo "pacman"
  elif command -v zypper >/dev/null 2>&1; then
    echo "zypper"
  elif command -v apk >/dev/null 2>&1; then
    echo "apk"
  else
    echo "Unknown package manager" >&2
    exit 1
  fi
}

# Function to update package index based on package manager
update_package_index() {
  local pm="$1"
  case "$pm" in
  apt-get)
    apt-get update
    ;;
  dnf | yum)
    "$pm" makecache
    ;;
  pacman)
    pacman -Sy
    ;;
  zypper)
    zypper refresh
    ;;
  apk)
    apk update
    ;;
  *)
    echo "No package index update for $pm" >&2
    ;;
  esac
}

# Function to install a package based on package manager
install_package() {
  local pm="$1"
  local pkg="$2"
  case "$pm" in
  apt-get)
    apt-get -y install --no-install-recommends "$pkg"
    ;;
  dnf | yum)
    "$pm" install -y "$pkg"
    ;;
  pacman)
    pacman -S --noconfirm "$pkg"
    ;;
  zypper)
    zypper install -y "$pkg"
    ;;
  apk)
    apk add "$pkg"
    ;;
  *)
    echo "Cannot install $pkg with $pm" >&2
    exit 1
    ;;
  esac
}

# Function to check if a package is installed (distro-agnostic)
is_package_installed() {
  local pkg="$1"
  # Try dpkg (Debian/Ubuntu), rpm (RHEL/Fedora), or command existence
  if command -v dpkg >/dev/null 2>&1 && dpkg -s "$pkg" >/dev/null 2>&1; then
    return 0
  elif command -v rpm >/dev/null 2>&1 && rpm -q "$pkg" >/dev/null 2>&1; then
    return 0
  elif command -v "$pkg" >/dev/null 2>&1; then
    # Fallback: check if the package provides a command (e.g., adduser)
    return 0
  fi
  return 1
}

# Main logic
PACKAGE_MANAGER=$(detect_package_manager)
echo "Detected package manager: $PACKAGE_MANAGER"

# Update package index
echo "Updating package index..."
update_package_index "$PACKAGE_MANAGER"

# Install dependencies if not already present
for dep in "${DEPENDENCIES[@]}"; do
  if ! is_package_installed "$dep"; then
    echo "$dep not found, installing..."
    install_package "$PACKAGE_MANAGER" "$dep"
  else
    echo "$dep already installed"
  fi
done

# check for exising user and remove if found
# this is to ensure the desired user has the correct
# UID GID
# check for existing user by name
echo "checking for existing username"
user=$(getent passwd "$_REMOTE_USER") || true
# delete it if existing
if [[ -n $user ]]; then
  echo "removing existing user"
  deluser "$(getent passwd "$_REMOTE_USER" | sed 's/:\+/ /g' | awk '{print $1}')"
fi
# check for existing user by id
user=$(getent passwd "$REMOTE_UID") || true
# delete it if existing
  echo "found existing user; removing"
  deluser "$(getent passwd 1001 | sed 's/:\+/ /g' | awk '{print $1}')"
if [[ -n $uid ]]; then
fi

# create the new group
if [[ -n $REMOTE_GID ]]; then
  GROUP_OPTS="$GROUP_OPTS --gid $REMOTE_GID"
fi
if [[ -n $REMOTE_GROUP ]]; then
  addgroup $GROUP_OPTS "$REMOTE_GROUP"
fi

# create the new user
if [[ -n $REMOTE_UID ]]; then
  USER_OPTS="$USER_OPTS -mou $REMOTE_UID"
fi
if [[ -n $SHELL ]]; then
  USER_OPTS="$USER_OPTS -s $SHELL"
fi
if [[ -n $REMOTE_GROUP ]]; then
  USER_OPTS="$USER_OPTS -g $REMOTE_GROUP"
fi
if [[ -n $_REMOTE_USER ]]; then
  echo "Adding user with command: useradd $USER_OPTS $_REMOTE_USER"
  useradd $USER_OPTS "$_REMOTE_USER"
fi

