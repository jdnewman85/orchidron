#!/bin/bash
set -euo pipefail

app_bin="orchidron"
as_root_flag="--as-root"

bundle_path="./container"
rootfs_name="rootfs"

cleanup=("${app_bin}" "state" "container_id" "${bundle_path}")

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

#Setup container environment
mkdir -p "${bundle_path}/${rootfs_name}" && cd "${bundle_path}"
#TODO Setup without docker
${sudo+"${sudo}"} docker export \
  "$(${sudo+"${sudo}"} docker create busybox)" |
  tar -C "${rootfs_name}" -xf -

#TODO Create spec without youki
printf "DEBUG: rootless_flag: '%s'\n" ${rootless_flag:+"${rootless_flag}"}
youki spec ${rootless_flag:+"${rootless_flag}"}

printf "TODO: !!! Modify(gen) config automatically\n"
"${EDITOR}" "./config.json"

cd ..

#Build
#TODO release support
cargo build
mv "./target/debug/${app_bin}" . || true

#Run
${sudo+"${sudo}"} ./${app_bin}

#Cleanup
#TODO --no-cleanup flag
${sudo+"${sudo}"} rm -fr "${cleanup[@]}"
