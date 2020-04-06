BlueberryPi
===========

A small business server for the RaspberryPi.

## Getting Started

The RaspberryPi uses an ARM processor architecture and therefore all
code will need to be emulated with qemu.  The development environment
is committed as code using Hashicorp Vagrant.  To get started you will
need [Vagrant](https://www.vagrantup.com) installed and some sort of
virtualization backend like VirtualBox or VMWare Desktop/Fusion
(recommended.)  Then, create the development environment like so:

```shell
$ vagrant up
```

This will provision a virtual machine with a minified version of Ubuntu
Linux, will update system software, and install all dependencies,
notably [qemu](https://www.qemu.org), [packer](https://packer.io), and the
[packer-builder-arm-image](https://github.com/solo-io/packer-builder-arm-image) plugin.

All vagrant provisioners execute by default, so once the environment is
provisioned the BlueberryPi ARM image will be automatically created as
well.  If you make changes to the BlueberryPi script and wish to re-run
the packer image creation without re-running all vagrant provisioning
scripts, run this command:

```shell
$ vagrant provision --provision-with build
```

When you're ready to shut down the VM to free up resources, run:

```shell
$ vagrant halt
```

If you want to completely wipe out the development environment (perhaps to
rebuild from scratch), run:

```shell
$ vagrant destroy
```

## Configuration

Vagrant and packer will try to copy `~/.ssh/id_ed25519.pub` from your host
to the image for key-based SSH authentication.  If you want to use a
different public key or don't want to use a key at all, make the appropriate
changes to `Vagrantfile` and `blueberrypi.json`.  But it's better to just
make a key if you don't already have one:

```shell
$ ssh-keygen -t ed25519
```
