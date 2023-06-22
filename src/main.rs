use std::{path::PathBuf, thread::sleep, time::Duration};

use libcontainer::container::{Container, ContainerStatus};

fn main() {
    println!("Hello containers!");

    let mut c = Container::new(
        "My Container",
        ContainerStatus::Creating,
        None,
        &PathBuf::from("./tutorial"),
        &PathBuf::from("./tutorial"),
    ).unwrap();

    while !c.can_start() {
        println!("Container status: {}", c.status());
        sleep(Duration::from_secs(1));
    }

    println!("Starting!");
    c.start().unwrap();
    println!("Container status: {}", c.status());
}
