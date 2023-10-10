sudo qemu-system-x86_64 -bios /usr/share/OVMF/x64/OVMF_CODE.fd -enable-kvm -cpu host -smp 4 -m 8192 -net nic,model=virtio -net user -drive file=/dev/nvme0n1
