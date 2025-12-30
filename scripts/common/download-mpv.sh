#!/bin/bash
set -e

MPV_VERSION="v0.41.0"
MPV_REPO_URL="https://github.com/mpv-player/mpv"
MPV_CACHE_DIR=".cache/mpv"

if [ "$1" = "git" ]; then
    echo "Cloning MPV from git using tag: ${MPV_VERSION}"
    mkdir -p "${MPV_CACHE_DIR}"
    git clone --depth 1 --branch "${MPV_VERSION}" "${MPV_REPO_URL}.git" "${MPV_CACHE_DIR}"
else
    MPV_LINK="${MPV_REPO_URL}/archive/refs/tags/${MPV_VERSION}.tar.gz"
    mkdir -p "${MPV_CACHE_DIR}"
    curl -Lsqo ".cache/mpv-${MPV_VERSION}.tar.gz" "${MPV_LINK}"
    tar -xf ".cache/mpv-${MPV_VERSION}.tar.gz" -C "${MPV_CACHE_DIR}" --strip-components=1
fi

echo "MPV source downloaded and extracted to .cache/mpv"
