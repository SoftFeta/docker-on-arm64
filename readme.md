## Docker install script for arm64 on armbian jessie

This is the first script that I wrote to install the newest docker for armbian
as the docker official repository does not include arm64 architecture.

This probably will work on other debian based jessie, and even other distro
but are completely untested.

## Install

```
git clone https://github.com/ip4368/docker-on-arm64.git && cd docker-on-arm64
sudo ./docker_inst.sh
```

## Tested Devices

* Odroid C2

## TODO

* Put into ansible playbook

## License

This project is licensed under the MIT License, look at LICENSE for more details
