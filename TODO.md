# TODO
- [X] Run a container via youki as library
- [ ] rootless
- [ ] Add self to docker group in the interim?
        https://www.tutorialspoint.com/running-docker-container-as-a-non-root-user
- [o] Setup build script
  - [X] --as-root flag
  - [ ] --no-cleanup flag
  - [ ] Install callback on error/Ctrl C for cleanup
- [ ] Console
- [ ] Tennant container setups
- [ ] Sockets
- [ ] Detached
- [ ] Limits
  - [ ] CPU
  - [ ] Memory
  - [ ] Disk
- [ ] Setting up roofs without docker
  - [ ] Something that replicates dockerfile features?
- [o] Use tmpfs for state
  - [ ] Size limit
  - [ ] UID and GID
  - [ ] rootfs also?
  - [X] via bash
          https://www.baeldung.com/linux/files-ram
  - [ ] via Rust library
          https://docs.rs/libmount/latest/libmount/struct.Tmpfs.html




# Issues
- unsure how to remount root with overlayfs
  - possibly via `mount -o move / /tmp/base`
  - or `mount -o remount`?
  - *POSSIBLE SOLUTION* Add as an option to youki itself?
  - *POSSIBLE SOLUTION* `root.readonly=false` and setup the overlay completely externally

- uid, gid mapping not working at all
  - neither in mounts
  - nor in linux user mapping
  - when setting uid/gid of user to match (1000), things work for src dir
  - adding `| .linux.namespaces += [{ "type": "user" }]` puts us in rootless

- Permission errors in `sh`
  - fe: when attempting to mount, or browse `/root`
  - whoami shows root
  - possibly because we don't have a tty?
  - or is it related to device permissions?
    - tried with with `| .linux.resources.devices[0].allow = true`, with no difference
    - tried with `| .process.terminal = true`, no change, but not ttyConsole yet

- Stdout/Stdin inherited from our own program
  - Seems runc either remains as a translation layer, or exits and leaves the container with the original stdio
  - dup2 is used to redirect stdio of the container when correcting /dev/null, and when using connect_sdio
    - [connect_stdio from setup_console](https://github.com/containers/youki/blob/a8a58570a51ee5e9f4ef4803aff74b83bdfe40be/crates/libcontainer/src/tty.rs#L131)
    - [reopen_dev_null](https://github.com/containers/youki/blob/a8a58570a51ee5e9f4ef4803aff74b83bdfe40be/crates/libcontainer/src/process/container_init_process.rs#L294)
  - [ ] Does console-socket fix?
  - [ ] Can we redirect the processes stdin/stdout with dup2?

# Links

- [youki docs](https://containers.github.io/youki/)
- [youki repo](https://github.com/containers/youki)
- [youki spec def](https://github.com/containers/youki/blob/a8a58570a51ee5e9f4ef4803aff74b83bdfe40be/crates/libcontainer/src/seccomp/fixture/config.json)

- [container fork/clone](https://github.com/containers/youki/blob/98c9ebab1d8e012a1e2f829e89cbc0214f119739/crates/libcontainer/src/process/fork.rs)
- [setsid syscall - forks](https://man7.org/linux/man-pages/man1/setsid.1.html)
- [note about container init setup](https://github.com/containers/youki/blob/a8a58570a51ee5e9f4ef4803aff74b83bdfe40be/docs/src/developer/integration_test.md#about-the-create-container-function)
- [connect_stdio from setup_console](https://github.com/containers/youki/blob/a8a58570a51ee5e9f4ef4803aff74b83bdfe40be/crates/libcontainer/src/tty.rs#L131)

- [youki create command](https://github.com/containers/youki/blob/a8a58570a51ee5e9f4ef4803aff74b83bdfe40be/crates/youki/src/commands/create.rs#L26)
- [youki issue - logpipe support](https://github.com/containers/youki/issues/731)
- [youki issue - checkpoint/restore](https://github.com/containers/youki/issues/142) - references detach and /dev/null redirects

- [runc terminal & stdio doc](https://github.com/opencontainers/runc/blob/main/docs/terminals.md)
- [hooks](https://github.com/opencontainers/runtime-spec/blob/main/config.md#prestart)
- [spec config](https://github.com/opencontainers/runtime-spec/blob/main/config.md)
- [spec linux config](https://github.com/opencontainers/runtime-spec/blob/main/config-linux.md#namespaces)
- [runc internals](https://terenceli.github.io/%E6%8A%80%E6%9C%AF/2021/12/23/runc-internals-2)
- [runc logpipe](https://github.com/opencontainers/runc/blob/main/init.go)

- [libmount](https://docs.rs/libmount/latest/libmount/struct.Tmpfs.html)

- [k8s container logging](https://kubernetes.io/docs/concepts/cluster-administration/logging/#how-nodes-handle-container-logs)

- [Using dup to change stdio](https://www.baeldung.com/linux/redirect-output-of-running-process)
- [dup2 manpage](https://man7.org/linux/man-pages/man2/dup2.2.html)


## overlayfs explanations
- [[https://wiki.archlinux.org/title/Overlay_filesystem]]
- [[https://adil.medium.com/container-filesystem-under-the-hood-overlayfs-5a8053fe3a0a]]
- [[https://www.adaltas.com/en/2021/06/03/linux-overlay-filesystem-docker/]]
- [[https://unix.stackexchange.com/questions/721874/jail-sandbox-process-on-an-overlay-root-and-track-changes]]
- [[https://askubuntu.com/a/109441]]
- [[https://jvns.ca/blog/2019/11/18/how-containers-work--overlayfs/]]
- [[https://gsthnz.com/posts/readonly_root_with_overlayfs/]]

- [[https://tbhaxor.com/pivot-root-vs-chroot-for-containers/]]
- [[https://www.redhat.com/sysadmin/net-namespaces]]
