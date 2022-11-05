# Bootstrap
A set of scripts to bootstrap a workstation, including dotfiles installable via ghar
To bootstrap a new system, these are the steps to run:
```
localectl set-keymap dvorak
pacman -Syyu
pacman -S git
git clone https://github.com/ajixuan/bootstrap.git
cd bootstrap/alis/
./alis.sh
```

##VirtualBox Setup
To make VirtualBox interface usable, the VBoxGuestAdditions is indispensable.
1. Download latest VBoxGuestAdditions
2. Insert the iso into optical drive
3. Mount optical drive by command `sudo mount /dev/cdrom /mnt/`
4. `cd /mnt && sudo sh ./VBoxLinuxAdditions.run`

##Missing deps
Currently there are some package dependencies that aren't being compiled. These will get added in the future
```
$ sudo apt install libfontconfig1-dev m4 openssl-dev libxcb-composite0-dev
``` 

##Compile tools:

```
build_env/set_runtime.sh
```

##Setup Vim
Start up vim and run `:PlugInstall`
