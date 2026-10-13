#!/usr/bin/env bash
set -ex
SCRIPT_PATH="$( cd "$(dirname "$0")" ; pwd -P )"

REPO="storytold/filmcraft"

# Map the Debian architecture to the naming used in the release assets
case "$(dpkg --print-architecture)" in
  amd64) ARCH="x86_64" ;;
  arm64) ARCH="aarch64" ;;
  *) echo "Unsupported architecture: $(dpkg --print-architecture)" >&2; exit 1 ;;
esac

apt-get update
apt-get install -y curl ca-certificates

# Use FILMCRAFT_VERSION if given (e.g. 0.7.2), otherwise resolve the latest release tag.
# The /releases/latest redirect avoids the unauthenticated GitHub API rate limit.
if [ -z "${FILMCRAFT_VERSION}" ]; then
  TAG=$(curl -fsSLI -o /dev/null -w '%{url_effective}' "https://github.com/${REPO}/releases/latest" | sed 's#.*/tag/##')
  FILMCRAFT_VERSION="${TAG#v}"
fi

DEB="filmcraft-${FILMCRAFT_VERSION}-linux-${ARCH}.deb"
BASE_URL="https://github.com/${REPO}/releases/download/v${FILMCRAFT_VERSION}"

mkdir -p /tmp/filmcraft
cd /tmp/filmcraft
curl -fsSL -o "${DEB}" "${BASE_URL}/${DEB}"
curl -fsSL -o SHA256SUMS.txt "${BASE_URL}/SHA256SUMS.txt"
grep " ${DEB}\$" SHA256SUMS.txt | sha256sum -c -

# Recommends pulls in mesa-vulkan-drivers / libegl-mesa0 for software rendering without a GPU
apt-get install -y --install-recommends "./${DEB}"

# Desktop shortcut
mkdir -p $HOME/Desktop
cp /usr/share/applications/ai.storyteller.filmcraft.desktop $HOME/Desktop/
chmod +x $HOME/Desktop/ai.storyteller.filmcraft.desktop
chown 1000:1000 $HOME/Desktop/ai.storyteller.filmcraft.desktop

# Cleanup
cd /
rm -rf /tmp/filmcraft
apt-get autoclean
rm -rf /var/lib/apt/lists/* /var/tmp/*
