#Ancillary virtual machine
## Prerequisites
KVM

##Configuration
### Important configuration parameters
Chose a name for the virtual machine, that does not exist. If unsure check with ´´´virsh list --all´´´
vmName

### VM interface and IP settings
vmMgmtIf
ipAddress
ipPrefix
gwAddress
dnsServerList




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

