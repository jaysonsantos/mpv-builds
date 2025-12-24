#!/bin/bash
set -e

MPV_VERSION=v0.41.0
MPV_LINK="https://github.com/mpv-player/mpv/archive/refs/tags/${MPV_VERSION}.tar.gz"

mkdir -p .cache/mpv
curl -Lsqo ".cache/mpv-${MPV_VERSION}.tar.gz" "${MPV_LINK}"

tar -xf ".cache/mpv-${MPV_VERSION}.tar.gz" -C .cache/mpv --strip-components=1

echo "MPV source downloaded and extracted to .cache/mpv"
