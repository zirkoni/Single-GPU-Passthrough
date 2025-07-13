### **My Setup**
**These instructions are for my personal reference but might be useful for others as well.**

- CPU: AMD Ryzen 5600X
- GPU: Nvidia 1660 Super
- OS: Arch Linux

### **Enable Virtualization in the UEFI/BIOS**
Enable AMD-V in the settings. Also, disable Resizable BAR Support (todo: check if ReBAR support is available for KVM).

### **Enable IOMMU**
Only grub instructions but the parameters should be the same for any other boot manager.

Edit <i>/etc/default/grub</i> and add the following kernel parameters:
```
GRUB_CMDLINE_LINUX_DEFAULT="... amd_iommu=on iommu=pt ..."
```

Generate the grub.cfg:
```sh
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

### **Install the Required Packages**
SSH is only needed if you want to be able to control your host machine while a guest is running. Enable SSH on your host and use another physical device to connect to your host system remotely. This is useful for debugging and shutting down the VM in case something goes wrong since you cannot see any output from the host on your monitor while the guest is running.
```sh
sudo pacman -S --needed qemu-desktop virt-manager libvirt edk2-ovmf dnsmasq openssh
```

### **Configure the System**
```sh
sudo usermod -aG kvm,input,libvirt $USER
```

```sh
sudo systemctl enable --now libvirtd
```

<b>Reboot</b>

These might be needed:
```sh
sudo virsh net-autostart default
sudo virsh net-start default
```

### **Setup the Guest OS**
Launch virt-manager and create a new virtual machine. Most default settings are fine but check in the <i>Overview</i> section that Chipset is set to Q35 and Firmware to UEFI.

Start the guest installation without the passthrough now. You don't have to actually install the guest OS yet, just starting it is enough so that some configuration files are created.

### **PCI Devices Setup**
First remove the following unnecessary devices:
```
Tablet
Display Spice
Sound ich*
Console
Channel (qemu-ga)
Channel (spice)
Video Virtio
```

Use the following script to list the IOMMU groups and attached devices:
```sh
#!/bin/bash
shopt -s nullglob
for g in `find /sys/kernel/iommu_groups/* -maxdepth 0 -type d | sort -V`; do
    echo "IOMMU Group ${g##*/}:"
    for d in $g/devices/*; do
        echo -e "\t$(lspci -nns ${d##*/})"
    done;
done;
```

Next click on <i>Add Hardware</i> and select <i>PCI Host Device</i>. You need to add the entire IOMMU group as listed in the output of the script here, not just the GPU VGA. For the GPU I had to add the following devices:
```
0000:06:00:0 NVIDIA Corporation TU116 [GeForce GTX 1660 SUPER]
0000:06:00:1 NVIDIA Corporation TU116 High Definition Audio Controller
0000:06:00:2 NVIDIA Corporation TU116 USB 3.1 Host Controller
0000:06:00:3 NVIDIA Corporation TU116 USB Type-C UCSI Controller
```

I also added the USB controller to get my keyboard and mouse working inside the guest OS:
```
0000:08:00:3 Advanced Micro Devices, Inc [AMD] Matisse USB 3.0 Host Controller
```

### **Dump the GPU vBIOS**
Run the following commands (the file name can be different, your choice):
```sh
echo 1 | sudo tee /sys/bus/pci/devices/0000:01:00.0/rom
sudo cat /sys/bus/pci/devices/0000:01:00.0/rom > /usr/share/vgabios/vbios.rom
echo 0 | sudo tee /sys/bus/pci/devices/0000:01:00.0/rom
```

Add the vBIOS path inside the hostdev block of your guest XML (/etc/libvirt/qemu/<guest_name>.xml):
```xml
...
<hostdev mode='subsystem' type='pci' managed='yes'>
  <source>
    ...
  </source>
  <rom file='/usr/share/vgabios/vbios.rom'/>
  ...
</hostdev>
...
```

### **Configure Libvirt Hooks**
- OPTION 1: Use the <i>setup_new_vm.sh</i> script
- OPTION 2: Configure manually

Copy the <i>qemu</i> script to (should not need to modify anything):
```sh
/etc/libvirt/hooks/qemu
```

Create the <i>start.sh</i> script to:
```sh
/etc/libvirt/hooks/qemu.d/<guest_name>/prepare/begin/start.sh
```
You'll need to modify it for your hardware/setup. I've given mine as an example.

Replace <i><guest_name></i> with your guest name (what you called your guest in virt-manager).

Do the same for the <i>stop.sh</i> script but to a different path:
```sh
/etc/libvirt/hooks/qemu.d/<guest_name>/release/end/stop.sh
```
Again, you'll need to modify the script for your setup.

You have to set the scripts as executable:
```sh
sudo chmod +x <path_to_file>
```


When you start the guest VM your host desktop should close, the screen goes black and after some time you should see the guest booting up.

### **Additional Sources**
I mostly followed this guide:
> [Complete-Single-GPU-Passthrough](https://github.com/QaidVoid/Complete-Single-GPU-Passthrough)<br/>

There are more sources and a troubleshooting guide at that link.
