# Bootstrap
A set of scripts to bootstrap a workstation, including dotfiles installable via ghar
To bootstrap a new system, these are the steps to run:
```
localectl set-keymap dvorak
pacman -Syy
pacman -S git
git clone https://github.com/ajixuan/bootstrap.git
cd bootstrap/alis/
./alis.sh
./alis-packages.sh
./alis-reboot.sh
```

##Archlinux Install:
1. Insert the Archlinux iso media
2. Download this dotfiles profile from github
3. Use alis to quickly bootstrap an arch linux instance
   Standard install configurations can be changed in the alis.conf

##VirtualBox Setup
To make VirtualBox interface usable, the VBoxGuestAdditions is indispensable.
1. Download latest VBoxGuestAdditions
2. Insert the iso into optical drive
3. Mount optical drive by command `sudo mount /dev/cdrom /mnt/`
4. `cd /mnt && sudo sh ./VBoxLinuxAdditions.run`

##Compile tools:
Note: need atleast 10GB of disk space
```
build_env/set_environment.sh
```

##Setup Vim
Start up vim and run `:PlugInstall`
