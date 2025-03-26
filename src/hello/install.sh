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

# Function to check if a package index update is required
is_index_update_required() {
  local pm="$1"
  local cache_dir=""
  local cache_age_limit=$((60 * 60 * 24)) # 24 hours in seconds (adjust as needed)

  case "$pm" in
  apt-get)
    cache_dir="/var/lib/apt/lists"
    # Check if the cache directory exists and has files
    if [ ! -d "$cache_dir" ] || [ -z "$(ls -A "$cache_dir")" ]; then
      return 0 # Update required if cache is missing or empty
    fi
    # Check if any cache file is older than the limit
    if find "$cache_dir" -type f -mtime +1 | grep -q .; then
      return 0 # Update required if files are older than 1 day
    fi
    return 1 # No update needed
    ;;
  dnf | yum)
    cache_dir="/var/cache/$pm"
    # Check if cache exists
    if [ ! -d "$cache_dir" ] || [ -z "$(ls -A "$cache_dir")" ]; then
      return 0 # Update required if cache is missing
    fi
    # Check cache expiration (dnf/yum uses metadata)
    if [ "$pm" = "dnf" ] && dnf check-update >/dev/null 2>&1 && [ $? -eq 100 ]; then
      return 0 # Update required if dnf indicates updates available
    elif [ "$pm" = "yum" ] && yum check-update >/dev/null 2>&1 && [ $? -eq 100 ]; then
      return 0 # Update required if yum indicates updates available
    fi
    # Fallback: check file age
    if find "$cache_dir" -type f -mtime +1 | grep -q .; then
      return 0 # Update required if files are older than 1 day
    fi
    return 1 # No update needed
    ;;
  pacman)
    cache_dir="/var/lib/pacman/sync"
    if [ ! -d "$cache_dir" ] || [ -z "$(ls -A "$cache_dir")" ]; then
      return 0 # Update required if sync db is missing
    fi
    # Check if db files are older than 1 day
    if find "$cache_dir" -type f -mtime +1 | grep -q .; then
      return 0 # Update required
    fi
    return 1 # No update needed
    ;;
  zypper)
    cache_dir="/var/cache/zypp"
    if [ ! -d "$cache_dir" ] || [ -z "$(ls -A "$cache_dir")" ]; then
      return 0 # Update required if cache is missing
    fi
    # Zypper has a refresh check
    if zypper --non-interactive refresh --services >/dev/null 2>&1 && [ $? -eq 7 ]; then
      return 0 # Update required if zypper indicates stale data
    fi
    # Fallback: check file age
    if find "$cache_dir" -type f -mtime +1 | grep -q .; then
      return 0 # Update required
    fi
    return 1 # No update needed
    ;;
  apk)
    cache_dir="/var/cache/apk"
    if [ ! -d "$cache_dir" ] || [ -z "$(ls -A "$cache_dir")" ]; then
      return 0 # Update required if cache is missing
    fi
    # Check if APK index is older than 1 day
    if find "$cache_dir" -type f -mtime +1 | grep -q .; then
      return 0 # Update required
    fi
    return 1 # No update needed
    ;;
  *)
    echo "Unknown package manager: $pm" >&2
    return 0 # Default to update for safety
    ;;
  esac
}

# Main logic
PACKAGE_MANAGER=$(detect_package_manager)
echo "Detected package manager: $PACKAGE_MANAGER"

# Update package index only if required
if is_index_update_required "$PACKAGE_MANAGER"; then
  echo "Updating package index..."
  update_package_index "$PACKAGE_MANAGER"
else
  echo "Package index is up-to-date, skipping update"
fi

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
uid=$(getent passwd "$REMOTE_UID") || true
# delete it if existing
if [[ -n $uid ]]; then
  echo "removing existing user"
  user=$(getent passwd "$REMOTE_UID" | sed 's/:\+/ /g' | awk '{print $1}')
  echo "command: deluser $user"
  deluser "$user"
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
if [[ -n $REMOTE_SHELL ]]; then
  USER_OPTS="$USER_OPTS -s $REMOTE_SHELL"
fi
if [[ -n $REMOTE_GROUP ]]; then
  USER_OPTS="$USER_OPTS -g $REMOTE_GROUP"
fi
if [[ -n $_REMOTE_USER ]]; then
  echo "Adding user with command: useradd $USER_OPTS $_REMOTE_USER"
  useradd $USER_OPTS "$_REMOTE_USER"
fi

