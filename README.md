```
  ___  _                  _                         , __    
 / (_)| |    |           | |                       /|/  \o  
 \__  | |  __|   _   ,_  | |   _   ,_    ,_         |___/   
 /    |/  /  |  |/  /  | |/ \_|/  /  |  /  |  |   | |    |  
 \___/|__/\_/|_/|__/   |_/\_/ |__/   |_/   |_/ \_/|/|    |_/
                                                 /|         
                                                 \|
```

ElderberryPi
============

A secure-by-default, self-healing, small business server for the RaspberryPi.

## Motivation

Security is difficult, transient, time-consuming, and expensive.

ElderberryPi enables small businesses and hobbyists alike to have enterprise-level
system hardening and security controls on affordable hardware.  Select the roles
you want to use and feel confident they are configured securely, by default.

Have assurance that the secure state of the system is kept over time.  ElderberryPi
uses Ansible scripts to apply its configuration with *idempotence.*  That means that
the system remains unchanged *unless* its configuration has deviated from the acceptable
state.  Because the configuration is continously reapplied every 30 minutes, this
makes ElderberryPi *self-healing.*

## Supported Roles

Presently, the following roles are supported (but more are coming soon!):

* NTP (with support for Windows client SNTP)
* DNS (with support for AD DNS dynamic updates)
* Active Directory Domain Controller (administer with Windows AD tools)
* PXE Server (work-in-progress)
* DHCP (only for BOOTP/PXE support presently)
* Certificate Authority (coming soon)
* Web Server (coming soon)
* Zymbit (for Real Time Clock support; root filesystem encryption coming soon)

## Getting Started

### Hardware

At present, ElderberryPi has only been tested on the Raspberry Pi 4 Model B Rev 1.2
with 4 GB of RAM.  A minimum of 4 GB microSD card is required.  The faster the better.

It's also highly recommended that you obtain the Zymbit Zymkey 4i security module if
you would like these features:
* Real Time Clock (essential for NTP and AD; you could use other hardware too)
* Root filesystem encryption at-rest
* Secure storage of CA root private key
* Optional physical perimeter security

### Software Prerequisites

You will need both [Vagrant](https://www.vagrantup.com) and [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
installed locally.  Ansible is needed locally to securely provision passwords from the host
during the image build steps.  There unfortunately is no Ansible client for Windows, so
you'll need to use Linux or macOS, which you could do in a virtual machine.  Vagrant is like
docker but it doesn't share the host's kernel; every Vagrant "box" is a dedicated virtual
machine.  Vagrant will provision a dedicated VM with all the tools and prerequisites needed
for building ElderberryPi.

### Configuring

```shell
$ ./configure.sh
```

Answer all the questions and select the roles you wish to enable.  That's it.  :)

If you need to reconfigure later, just pass the option:

```shell
$ ./configure.sh --reset-config
```

### Build Steps

1. Vagrant will provision a Ubuntu VM and will download all the build tools including
   QEMU and Packer.
2. Packer will download the Ubuntu 18.04 Bionic 64-bit ARM image for the Raspberry Pi 4.
   (We don't support 20.04 Focal because Zymbit doesn't yet support it.)
3. [packer-builder-arm](https://github.com/mkaczanowski/packer-builder-arm) will extract
   the image, mount the filesystems, and use qemu to execute shell scripts defined in
   `vagrant/elderberrypi.json` in Packer provisioners.  It also copies all the ansible
   scripts, keys, and configuration files into the image.
4. Packer outputs the image, ready to be flashed.

### Flashing the image

```shell
$ sudo dd if=vagrant/elderberrypi.img of=/dev/disk2 bs=4096
```

Be sure to change `/dev/disk2` to point to your SD card.

### Running ElderberryPi

If you have the Zymbit Zymkey 4i security module, be sure to install that per the
[instructions](https://community.zymbit.com/t/getting-started-with-zymkey-4i/) along
with a CR1025 battery *before* powering on the Rasperry Pi unit.

Afterward, install the SD card and power on the device.  Within 30 seconds you should
be able to SSH into it.  The IP address is what you configured.  Don't forget to use
the appropriate SSH key.  If you generated a key, the command might look similar to this:

```shell
$ ssh -i ~/.ssh/elderberrypi.key ubuntu@192.168.2.2
```

Note that the default user account is `ubuntu`.

To monitor ansible progress:

```shell
$ sudo tail -n 50 -f /srv/elderberrypi/elderberrypi.log
```

The ansible scripts will run automatically on every boot and every 30 minutes.
However, you can force them to run if you'd like:

```shell
$ sudo systemctl start elderberrypi &
```

If systemctl sees that the service is already running, it won't try to start it again.
The 30 minute timer starts at the completion of the script.

### Cleaning up

Vagrant will keep the VM running on your host until you shut it down.

```shell
$ vagrant halt
```

If you want to completely wipe out the build environment (perhaps to rebuild from
scratch or just because you don't need it anymore), run:

```shell
$ vagrant destroy
```

## What's Next?

Security and compliance go hand-in-hand.  In the near future we intend to migrate the
CentOS [security policy content](https://github.com/ComplianceAsCode/content) to Ubuntu,
leveraging OpenSCAP and other related Compliance-as-Code tools to enable ElderberryPi
users to comply with DISA STIG, PCI DSS, HIPAA, and other security and privacy frameworks
and regulations.

Alternatively, or perhaps in addition to the above, if RedHat releases a supported arm64
image for the Raspberry Pi and Zymbit supports it, we may migrate away from Ubuntu or offer
both distributions and supported options.
