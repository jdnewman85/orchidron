#!/bin/bash
set -euo pipefail
#set -x

app_bin="orchidron"
rootless_flag="r"
rootless_long_flag="rootless"
rootless_description="Run rootless and without sudo (currently doesn't work)"
skip_clean_flag="c"
skip_clean_long_flag="skip-clean"
skip_clean_description="Skip cleanup of tmpfs"
help_flag="h"
help_long_flag="help"
help_description="TODO! help"

#TODO Use these arrays?
flags=('r' 'c' 'h')
long_flags=('rootless', 'skip-clean', 'help')
descriptions=(
  "Run rootless and without sudo (currently doesn't work)"
  "Skip cleanup of tmpfs"
  "TODO! help"
)

youki_rootless_flag="rootless"

working_dir="${PWD}"

tmpfs_path="${working_dir}/tmpfs"
bundle_path="${tmpfs_path}/bundle"
rootfs_path="${bundle_path}/rootfs"
#container_state_path="${tmpfs_path}/state"

cleanup_targets=("${working_dir}/${app_bin}" "${tmpfs_path}")

#TODO Array of flags/descriptions?
function usage() {
  cat << EOF
Usage: $0 [-${help_flag}${rootless_flag}${skip_clean_flag}]
	-${help_flag},       --${help_long_flag}  ${help_description}
	-${rootless_flag},   --${rootless_long_flag}  ${rootless_description}
	-${skip_clean_flag}, --${skip_clean_long_flag}  ${skip_clean_description}
EOF
  exit 1
}

rootless=
skip_clean=

old_IFS="${IFS}"
IFS='' getops_flags="${flags[*]}"
IFS="${old_IFS}"

while getopts "${getops_flags}-:" arg; do
  case "${arg}" in
    "${rootless_flag}") rootless=true;;
    "${skip_clean_flag}") skip_clean=true;;
    -) case ${OPTARG} in
      "${rootless_long_flag}") rootless=true;;
      "${skip_clean_long_flag}") skip_clean=true;;
      "${help_long_flag}" | *) usage;;
    esac;;
    "${help_flag}" | *) usage;;
  esac
done

# If not rootless, use sudo
sudo=
[ ! "${rootless}" ] && sudo="sudo"

#Cleanup
#TODO --no-cleanup flag
function cleanup() {
  ${sudo+"${sudo}"} umount "${tmpfs_path}" || true
  ${sudo+"${sudo}"} rm -r "${cleanup_targets[@]}"
}
[ ! ${skip_clean} ] && trap cleanup EXIT

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
echo "spec rootless flag: ${rootless:+"--${youki_rootless_flag}"}"
(cd "${bundle_path}" && youki spec ${rootless:+"--${youki_rootless_flag}"})

#TODO Generate config
#TODO Use better temp filename
config_path="${bundle_path}/config.json"
additional_hooks='{
  "createRuntime": [
    {
      "path": "/bin/mkdir",
      "args": [
        "mkdir",
        "/tmp/a"
      ]
    },
    {
      "path": "/bin/mount",
      "args": [
        "mount",
        "-o",
        "move",
        "/",
        "/tmp/a"
      ]
    }
  ]
}'
#additional_hooks='{ }' #TODO TEMP
additional_mounts='[
  {
    "destination": "/temp",
    "type": "none",
    "source": "/home/sci/projects/rust/orchidron/temp",
    "options": ["rbind", "rw"],
    "uidMappings": [
      {
        "containerID": 0,
        "hostID": 1000,
        "size": 1
      }
    ],
    "gidMappings": [
      {
        "containerID": 0,
        "hostID": 1000,
        "size": 1
      }
    ]
  }
]'
additional_linux_fields='{
  "linux": {
    "uidMappings": [
      {
        "containerID": 0,
        "hostID": 1000,
        "size": 1
      }
    ],
    "gidMappings": [
      {
        "containerID": 0,
        "hostID": 1000,
        "size": 1
      }
    ]
  }
}'

jq '
.process.args = $command
  | .hooks = $hooks
  | .mounts += $add_mounts
  | . * $add_linux_fields
  | .linux.resources.devices[0].allow = true
  | .process.user.uid = 0
  | .process.user.gid = 0
  | .process.terminal = true
' \
  --argjson command '["sh"]' \
  --argjson hooks "${additional_hooks}" \
  --argjson add_mounts "${additional_mounts}" \
  --argjson add_linux_fields "${additional_linux_fields}" \
  "${config_path}" \
  >> "${config_path}.tmp"
mv "${config_path}.tmp" "${config_path}"

#Build
#TODO release support
cargo build
mv "./target/debug/${app_bin}" .

#Run
${sudo+"${sudo}"} ./${app_bin}

