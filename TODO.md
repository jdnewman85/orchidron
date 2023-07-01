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




Issues:
- Stdout/Stdin inherited from our own program
  - Seems runc either remains as a translation layer, or exits and leaves the container with the original stdio
  - dup2 is used to redirect stdio of the container when correcting /dev/null, and when using connect_sdio
    - [connect_stdio from setup_console](https://github.com/containers/youki/blob/a8a58570a51ee5e9f4ef4803aff74b83bdfe40be/crates/libcontainer/src/tty.rs#L131)
    - [reopen_dev_null](https://github.com/containers/youki/blob/a8a58570a51ee5e9f4ef4803aff74b83bdfe40be/crates/libcontainer/src/process/container_init_process.rs#L294)
- [ ] Does console-socket fix?
- [ ] Can we redirect the processes stdin/stdout with dup2?

- Links
- [youki docs](https://containers.github.io/youki/)
- [youki repo](https://github.com/containers/youki)

- [container fork/clone](https://github.com/containers/youki/blob/98c9ebab1d8e012a1e2f829e89cbc0214f119739/crates/libcontainer/src/process/fork.rs)
- [runc terminal & stdio doc](https://github.com/opencontainers/runc/blob/main/docs/terminals.md)
- [setsid syscall - forks](https://man7.org/linux/man-pages/man1/setsid.1.html)
- [note about container init setup](https://github.com/containers/youki/blob/a8a58570a51ee5e9f4ef4803aff74b83bdfe40be/docs/src/developer/integration_test.md#about-the-create-container-function)
- [connect_stdio from setup_console](https://github.com/containers/youki/blob/a8a58570a51ee5e9f4ef4803aff74b83bdfe40be/crates/libcontainer/src/tty.rs#L131)

- [youki create command](https://github.com/containers/youki/blob/a8a58570a51ee5e9f4ef4803aff74b83bdfe40be/crates/youki/src/commands/create.rs#L26)
- [runc internals](https://terenceli.github.io/%E6%8A%80%E6%9C%AF/2021/12/23/runc-internals-2)
- [runc logpipe](https://github.com/opencontainers/runc/blob/main/init.go)
- [youki issue - logpipe support](https://github.com/containers/youki/issues/731)
- [youki issue - checkpoint/restore](https://github.com/containers/youki/issues/142) - references detach and /dev/null redirects

- [libmount](https://docs.rs/libmount/latest/libmount/struct.Tmpfs.html)

- [k8s container logging](https://kubernetes.io/docs/concepts/cluster-administration/logging/#how-nodes-handle-container-logs)

- [Using dup to change stdio](https://www.baeldung.com/linux/redirect-output-of-running-process)
- [dup2 manpage](https://man7.org/linux/man-pages/man2/dup2.2.html)
