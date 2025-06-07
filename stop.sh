#!/bin/bash
set -x

# Attach USB device to host
virsh nodedev-reattach pci_0000_08_00_3

# Attach GPU devices to host
# Use your GPU and HDMI Audio PCI host device
virsh nodedev-reattach pci_0000_06_00_0
virsh nodedev-reattach pci_0000_06_00_1
virsh nodedev-reattach pci_0000_06_00_2
virsh nodedev-reattach pci_0000_06_00_3

# Unload vfio module
modprobe -r vfio-pci

# Rebind framebuffer to host
echo "efi-framebuffer.0" > /sys/bus/platform/drivers/efi-framebuffer/bind

# Load NVIDIA kernel modules
modprobe drm_ttm_helper
modprobe nvidia_drm
modprobe nvidia_modeset
modprobe nvidia_uvm
modprobe nvidia

# Bind VTconsoles: might not be needed
echo 1 > /sys/class/vtconsole/vtcon0/bind
echo 1 > /sys/class/vtconsole/vtcon1/bind

# Restart Display Manager
systemctl start display-manager
