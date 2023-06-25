use std::error::Error;
use std::{thread::sleep, time::Duration};

use libcontainer::container::{ContainerStatus, builder::ContainerBuilder};

use libcontainer::syscall::syscall::create_syscall;

use nix::{
    sys::{
        signal,
        signalfd::SigSet,
        wait::{waitpid, WaitPidFlag, WaitStatus},
    },
    unistd::Pid,
};

fn main() {
    println!("Hello containers!");
    let sc = create_syscall();

    let c_builder = ContainerBuilder::new(
        "/home/sci/projects/rust/orchidron/container_id".to_owned(),
        sc.as_ref(),
    )
        .with_root_path("./state").unwrap()
        .as_init("./container")
        .with_detach(false)
        .with_systemd(false)
    ;
    let mut c = c_builder.build().unwrap();
    dbg!(c.systemd());
    c.start().unwrap();

    /*
    while c.status().eq(&ContainerStatus::Running) {
        println!("Container status: {}", c.status());
        sleep(Duration::from_secs(1));
        c.refresh_status().unwrap();
    }
    */

    /*
    let pid = c.pid().unwrap();
    let r = handle_foreground(pid).unwrap();
    println!("Result: {r}");
    */
}

fn handle_foreground(init_pid: Pid) -> Result<i32, Box<dyn Error>> {
    // We mask all signals here and forward most of the signals to the container
    // init process.
    let signal_set = SigSet::all();
    signal_set
        .thread_block()?;
    loop {
        match signal_set
            .wait()?
        {
            signal::SIGCHLD => {
                // Reap all child until either container init process exits or
                // no more child to be reaped. Once the container init process
                // exits we can then return.
                loop {
                    match waitpid(None, Some(WaitPidFlag::WNOHANG))? {
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
                println!("Moogles {signal}");
            }
        }
    }
}
