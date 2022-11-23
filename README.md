#Ancillary VM

## Prerequisites
KVM

##Configuration
### Important configuration parameters
Chose a name for the virtual machine, that does not exist. If unsure check with ```virsh list --all```
vmName="ancillary"


### VM interface and IP settings
vmMgmtIf
ipAddress
ipPrefix
gwAddress
dnsServerList

### Virtual machine settings
It is possible to pin CPUs to the VM via ```vmCpuSet```. This makes most sense if those are isolated, a check via ```cat /proc/cmdline``` helps to clarify on it. 

Setting ```vmCpuSet=""``` does not strictly assign CPUs to the VM and leaves the assignment to KVM/qemu. Be aware the that CPUs may be shared across multiple VMs which may degrade the VM's performance. This is currently not supported.

Memory and vmVcpus should be set according to the services that will be enabled on the VM. 



Operating Sytem Parameters
Ubuntu Version
osVersion
 - 20.04
 - 18.04


Virtual Machine parameters
Increase image size 
incImageSize

Networking
Management Bridge interconnecting the ancillary VM to the management network
vmMgmtBridge

