#!/bin/bash

# Debug
#exec 19>/home/zirkoni/qemu_debug.log
#BASH_XTRACEFD=19

set -x

# Start SSH daemon
systemctl start --now sshd

# Stop display manager
systemctl stop greetd
systemctl stop display-manager

# Stop sound
pulse_pid=$(pgrep -u zirkoni pipewire-pulse)
kill $pulse_pid
pipewire_pid=$(pgrep -u zirkoni pipewire)
kill $pipewire_pid

# Unbind VTconsoles: might not be needed
echo 0 > /sys/class/vtconsole/vtcon0/bind
echo 0 > /sys/class/vtconsole/vtcon1/bind

sleep 5

# Unbind EFI Framebuffer
echo efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/unbind

# Unload NVIDIA kernel modules
modprobe -r nvidia_drm nvidia_modeset nvidia_uvm nvidia drm_ttm_helper

# Detach GPU devices from host
# Use your GPU and HDMI Audio PCI host device
virsh nodedev-detach pci_0000_06_00_0
virsh nodedev-detach pci_0000_06_00_1
virsh nodedev-detach pci_0000_06_00_2
virsh nodedev-detach pci_0000_06_00_3

# Detach USB from host
virsh nodedev-detach pci_0000_08_00_3


# Load vfio module
modprobe vfio-pci
