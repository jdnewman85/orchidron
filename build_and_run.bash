#!/bin/bash
set -euo pipefail

app_bin="orchidron"
as_root_flag="--as-root"

working_dir="${PWD}"

tmpfs_path="${working_dir}/tmpfs"
bundle_path="${tmpfs_path}/bundle"
rootfs_path="${bundle_path}/rootfs"
#container_state_path="${tmpfs_path}/state"

cleanup_targets=("${working_dir}/${app_bin}" "${tmpfs_path}")

function usage() {
  #TODO TEMP - Only support as-root atm
  #printf "Usage: %s [%s]\n" "$0" "${as_root_flag}"
  printf "Usage: %s %s\n" "$0" "${as_root_flag}"
  exit 1
}

first_arg=${1-}

if [ "$#" -gt 1 ]; then usage; fi
if [ "$#" -eq 1 ] && [ "${first_arg}" != "$as_root_flag" ]; then usage; fi

#TODO TEMP - Only support as-root atm
if [ "${first_arg}" != "$as_root_flag" ]; then usage; fi

# If as_root, use sudo
sudo="${first_arg/${as_root_flag}/sudo}"
rootless_flag="--rootless"
[ -n "${first_arg}" ] && rootless_flag=""

#Cleanup
#TODO --no-cleanup flag
function cleanup() {
  ${sudo+"${sudo}"} umount "${tmpfs_path}" || true
  ${sudo+"${sudo}"} rm -r "${cleanup_targets[@]}"
}
trap cleanup EXIT

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
printf "DEBUG: rootless_flag: '%s'\n" ${rootless_flag:+"${rootless_flag}"}
(cd "${bundle_path}" && youki spec ${rootless_flag:+"${rootless_flag}"})

#TODO Generate config
jq '.process.args = $command' \
  --argjson command '["echo", "w00tness"]' \
  "${bundle_path}/config.json" \
  >> "${bundle_path}/config.json.tmp"
mv "${bundle_path}/config.json.tmp" "${bundle_path}/config.json"

#Build
#TODO release support
cargo build
mv "./target/debug/${app_bin}" . || true

#Run
${sudo+"${sudo}"} ./${app_bin}

