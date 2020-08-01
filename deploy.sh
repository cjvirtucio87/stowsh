#!/bin/bash

set -e

### deploy.sh
### [summary]
### Script for creating and uploading releases.
###
### [description]
### Script for creating and uploading releases. Requires .NET Core.
###
### [usage]
### - Run the script:
### ./deploy.sh

readonly ROOT_DIR="$(readlink --canonicalize --no-newline "$(dirname "$0")")"
readonly NET_TOOLS_DIR="${ROOT_DIR}/.net-tools"
readonly NET_TOOLS_VERSION="3.2.31"
readonly NET_TOOLS_COMMIT_FILE="${NET_TOOLS_DIR}/.${NET_TOOLS_VERSION}"

function cleanup {
  >&2 echo "begin cleanup"
  if [[ -d "${TEMP_DIR}" ]]; then
    >&2 echo "purging TEMP_DIR [${TEMP_DIR}]"
    rm --recursive --force "${TEMP_DIR}"
  fi
  >&2 echo "end cleanup"
}

function create_release {
  local api_release_url="$1"
  local github_api_token="$2"
  local release_json="$3"

  >&2 echo "creating release"
  curl \
    --data "${release_json}" \
    -H "Authorization: token ${github_api_token}" \
    "${api_release_url}"
}

function get_version {
  "${NET_TOOLS_DIR}/nbgv" get-version -v Version | sed -E "s/([[:digit:]]+.[[:digit:]]+.[[:digit:]]+).[[:digit:]]+/\1/g"
}

function install_nbgv {
  if [[ -f "${NET_TOOLS_COMMIT_FILE}" ]]; then
    return
  fi

  dotnet \
      tool \
        install \
          --tool-path "${NET_TOOLS_DIR}" \
          nbgv \
            --version "${NET_TOOLS_VERSION}"

  touch "${NET_TOOLS_COMMIT_FILE}"
}


function upload_release_asset {
  local uploads_release_url="$1"
  local github_api_token="$2"
  local release_id="$3"
  local release_dir="$4"
  local asset_name="$5"

  >&2 echo 'uploading release asset'
  tar \
      --gunzip \
      --create \
      --verbose \
      --to-stdout \
      --directory "${release_dir}" \
      --exclude './lib/shell-lib/.git' \
      . \
      | curl \
        -X POST \
        -H "Authorization: token ${github_api_token}" \
        -H "Content-Type: application/octet-stream" \
        --data-binary '@-' \
        "${uploads_release_url}/${release_id}/assets?name=${asset_name}"
}

function main {
  echo "starting deploy"
  install_nbgv

  TEMP_DIR="$(mktemp --directory)"
  trap cleanup EXIT

  local version
  version="$(get_version)"
  >&2 echo "releasing version: ${version}"

  local release_yaml
  release_yaml="${TEMP_DIR}/release.yml"
  touch "${release_yaml}"
  clconf --ignore-env --yaml "${release_yaml}" setv 'tag_name' "stowsh-${version}"
  clconf --ignore-env --yaml "${release_yaml}" setv 'target_commitish' 'master'
  clconf --ignore-env --yaml "${release_yaml}" setv 'name' "stowsh-${version}"
  clconf --ignore-env --yaml "${release_yaml}" setv 'body' "stowsh release, version ${version}"
  clconf --ignore-env --yaml "${release_yaml}" setv 'draft' 'false'
  clconf --ignore-env --yaml "${release_yaml}" setv 'prerelease' 'true'

  local clconf_args=(
    --yaml "${ROOT_DIR}/secrets.yml"
    --yaml "${ROOT_DIR}/secrets.override.yml"
  )
  local release_json
  release_json="$(clconf --yaml "${release_yaml}" --ignore-env getv --as-json --pretty | sed -E 's,"(false|true)",\1,g')"

  local release_response
  release_response="$(create_release \
    "$(clconf getv "${clconf_args[@]}" 'api_release_url')" \
    "$(clconf getv "${clconf_args[@]}" 'github_api_token')" \
    "${release_json}")"

  local release_id
  release_id="$(clconf --yaml <(echo "${release_response}") --ignore-env getv 'id')"

  local asset_name
  asset_name="cjvirtucio87-stowsh-${version}.tar.gz"

  local upload_release_asset_response
  upload_release_asset_response="$(upload_release_asset \
    "$(clconf "${clconf_args[@]}" getv 'uploads_release_url')" \
    "$(clconf "${clconf_args[@]}" getv 'github_api_token')" \
    "${release_id}" \
    "${ROOT_DIR}/app" \
    "${asset_name}")"

  >&2 clconf --yaml <(echo "${upload_release_asset_response}")

  echo "completed deploy"
}

main "$@"
