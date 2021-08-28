# Bootstrap
A set of scripts to bootstrap a workstation, including dotfiles installable via ghar
To bootstrap a new system, these are the steps to run:
```
localectl set-keymap dvorak
pacman -Syy
pacman -S git
git clone https://github.com/ajixuan/bootstrap.git
cd dotfiles/alis/
./alis.sh
```

Setup profile:
```
build_env/set_environment.sh
```

