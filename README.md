# Bootstrap
A set of scripts to bootstrap a workstation, including dotfiles installable via ghar
To bootstrap a new system, these are the steps to run:
```
localectl set-keymap dvorak
pacman -Syy
pacman -S git
git clone https://github.com/ajixuan/dotfiles.git
cd dotfiles/alis/
./alis.sh
```

Before you are able to run the build scripts you need to first
```
build_env/set_environment.sh
```

