use std::error::Error;
use std::{thread::sleep, time::Duration};

use libcontainer::container::Container;
use libcontainer::container::{builder::ContainerBuilder, ContainerStatus};

use libcontainer::syscall::syscall::create_syscall;

use nix::{
    sys::{
        signal,
        signalfd::SigSet,
        wait::{waitpid, WaitPidFlag, WaitStatus},
    },
    unistd::Pid,
};

enum EndOp {
    DumbWait,
    HandleForeground,
}

fn main() -> Result<(), Box<dyn Error>> {
    println!("Hello containers!");
    let syscall = create_syscall();

    let container_builder = ContainerBuilder::new(
        "/home/sci/projects/rust/orchidron/tmpfs/state".to_owned(),
        syscall.as_ref(),
    )
//    .with_root_path("/home/sci/projects/rust/orchidron/tmpfs/state_root").unwrap()
    .as_init("/home/sci/projects/rust/orchidron/tmpfs/bundle")
    .with_detach(false)
    .with_systemd(false);
    let mut container = container_builder.build().unwrap();
    dbg!(container.systemd());
    container.start().unwrap();

    //let end_op = EndOp::DumbWait;
    let end_op = EndOp::HandleForeground;
    match end_op {
        EndOp::DumbWait => wait_while_running(container).unwrap(),
        EndOp::HandleForeground => {
            let pid = container.pid().ok_or("No PID for container: {container}").unwrap();
            handle_foreground(pid).unwrap();
        }
    }

    Ok(())
}

fn wait_while_running(mut container: Container) -> Result<(), Box<dyn Error>> {
    while container.status().eq(&ContainerStatus::Running) {
        println!("Container status: {}", container.status());
        sleep(Duration::from_secs(1));
        container.refresh_status().unwrap();
    }
    Ok(())
}

// We must act as subreaper under some circumstances
// From youji: https://github.com/containers/youki/blob/dfe6ee80bc780449fffcf22ecf6618c7c30791ae/crates/youki/src/commands/run.rs#L58
// Runc's reasoning: https://github.com/opencontainers/runc/blob/main/docs/terminals.md#detached
fn handle_foreground(init_pid: Pid) -> Result<i32, Box<dyn Error>> {
    // We mask all signals here and forward most of the signals to the container
    // init process.
    let signal_set = SigSet::all();
    signal_set.thread_block().unwrap();
    loop {
        match signal_set.wait().unwrap() {
            signal::SIGCHLD => {
                // Reap all child until either container init process exits or
                // no more child to be reaped. Once the container init process
                // exits we can then return.
                loop {
                    match waitpid(None, Some(WaitPidFlag::WNOHANG)).unwrap() {
                        WaitStatus::Exited(pid, status) => {
                            if pid.eq(&init_pid) {
                                return Ok(status);
                            }

                            // Else, some random child process exited, ignoring...
                        }
                        WaitStatus::Signaled(pid, signal, _) => {
                            if pid.eq(&init_pid) {
                                return Ok(signal as i32);
                            }

                            // Else, some random child process exited, ignoring...
                        }
                        WaitStatus::StillAlive => {
                            // No more child to reap.
                            break;
                        }
                        _ => {}
                    }
                }
            }
            signal::SIGURG => {
                // In `runc`, SIGURG is used by go runtime and should not be forwarded to
                // the container process. Here, we just ignore the signal.
            }
            signal::SIGWINCH => {
                // TODO: resize the terminal
            }
            signal => {
                // There is nothing we can do if we fail to forward the signal.
                println!("Unhandled signal: {signal}");
            }
        }
    }
}
