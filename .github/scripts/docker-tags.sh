#!/usr/bin/env bash
set -xeuo pipefail

# Generates docker images tags for the docker/build-push-action@v2 action depending on the branch/tag.

# Config
IMAGE_TAG_BASE="${IMAGE}:php${VERSION}"

# Registries
declare -a registryArr
registryArr+=("docker.io") # Docker Hub
registryArr+=("ghcr.io") # GitHub Container Registry

# Image tags
declare -a imageTagArr

# On every build
GIT_SHORT_SHA="${GITHUB_SHA:1:7}" # Short SHA (7 characters)
imageTagArr+=("${IMAGE_TAG_BASE}-build-${GIT_SHORT_SHA}")

# develop => version-edge
if [[ "${GITHUB_REF}" == "refs/heads/develop" ]]; then
	imageTagArr+=("${IMAGE_TAG_BASE}-edge")
fi

# master => version
if [[ "${GITHUB_REF}" == "refs/heads/master" ]]; then
	imageTagArr+=("${IMAGE_TAG_BASE}")
fi

# tags/v1.0.0 => 1.0
if [[ "${GITHUB_REF}" =~ "refs/tags/" ]]; then
	# Extract version parts from release tag
	IFS='.' read -a release_arr <<< "${GITHUB_REF#refs/tags/}"
	releaseMajor=${release_arr[0]#v*}  # 2.7.0 => "2"
	releaseMinor=${release_arr[1]}  # "2.7.0" => "7"
	imageTagArr+=("${IMAGE_TAG_BASE}")
	imageTagArr+=("${IMAGE_TAG_BASE}-${releaseMajor}")
	imageTagArr+=("${IMAGE_TAG_BASE}-${releaseMajor}.${releaseMinor}")
fi

# Build an array of registry/image:tag values
declare -a repoImageTagArr
for registry in ${registryArr[@]}; do
	for imageTag in ${imageTagArr[@]}; do
		repoImageTagArr+=("${registry}/${imageTag}")
	done
done

# Print with new lines for output in build logs
(IFS=$'\n'; echo "${repoImageTagArr[*]}")
# Using newlines in outputs variables does not seem to work, so we'll use comas
(IFS=$','; echo "::set-output name=tags::${repoImageTagArr[*]}")
