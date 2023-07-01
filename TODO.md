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
- [ ] Does console-socket fix?
- [ ] Can we redirect the processes stdin/stdout with dup2?

- Useful links to things related to this:
- [connect_stdio from setup_console](https://github.com/containers/youki/blob/a8a58570a51ee5e9f4ef4803aff74b83bdfe40be/crates/libcontainer/src/tty.rs#L131)
