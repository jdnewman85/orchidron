#!/bin/bash
set -euo pipefail

app_bin="orchidron"
rootless_flag="r"
skip_clean_flag="c"

youki_rootless_flag="--rootless"

working_dir="${PWD}"

tmpfs_path="${working_dir}/tmpfs"
bundle_path="${tmpfs_path}/bundle"
rootfs_path="${bundle_path}/rootfs"
#container_state_path="${tmpfs_path}/state"

cleanup_targets=("${working_dir}/${app_bin}" "${tmpfs_path}")

function usage() {
  printf "Usage: %s [-%s] [-%s]\n" "$0" \
    "${rootless_flag}" \
    "${skip_clean_flag}"
  exit 1
}

rootless=
skip_clean=

while getopts "rch" arg; do
  case "${arg}" in
    r) rootless=true;;
    c) skip_clean=true;;
    h | *) usage;;
  esac
done

# If not rootless, use sudo
sudo=
! [ "${rootless}" ] && sudo="sudo"

#Cleanup
#TODO --no-cleanup flag
function cleanup() {
  ${sudo+"${sudo}"} umount "${tmpfs_path}" || true
  ${sudo+"${sudo}"} rm -r "${cleanup_targets[@]}"
}
! [ ${skip_clean} ] && trap cleanup EXIT

#Setup container environment

#tmpfs for state
mkdir "${tmpfs_path}"
${sudo+"${sudo}"} mount tmpfs -t tmpfs "${tmpfs_path}"
mkdir "${bundle_path}" "${rootfs_path}"

#Image
#TODO Setup without docker
${sudo+"${sudo}"} docker export \
  "$(${sudo+"${sudo}"} docker create busybox)" |
  tar -C "${rootfs_path}" -xf -

#TODO Create spec without youki
(cd "${bundle_path}" && youki spec ${rootless:+"${youki_rootless_flag}"})

#TODO Generate config
jq '.process.args = $command' \
  --argjson command '["sh"]' \
  "${bundle_path}/config.json" \
  >> "${bundle_path}/config.json.tmp"
mv "${bundle_path}/config.json.tmp" "${bundle_path}/config.json"

#Build
#TODO release support
cargo build
mv "./target/debug/${app_bin}" . || true

#Run
${sudo+"${sudo}"} ./${app_bin}

