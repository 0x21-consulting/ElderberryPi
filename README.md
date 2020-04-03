BlueberryPi
===========

A small business server for the RaspberryPi.

## Getting Started

The RaspberryPi uses an ARM processor architecture and therefore all
code will need to be emulated with qemu.  The development environment
is committed as code using Hashicorp Vagrant.  To get started you will
need Vagrant installed and some sort of virtualization backend like
VirtualBox or VMWare Desktop/Fusion (recommended.)  Then, create the
development environment like so:

```shell
$ vagrant up
```

This will provision a virtual machine with a minified version of Ubuntu
Linux, will update system software, and install all dependencies,
notably qemu, packer, and the packer-builder-arm-image plugin.

All vagrant provisioners execute by default, so once the environment is
provision the BlueberryPi ARM image will be automatically created as
well.  If you make changes to the BlueberryPi script and wish to re-run
the packer image creation without re-running all vagrant provisioning
scripts, run this command:

```shell
$ vagrant provision --provision-with build
```

