#Ancillary VM

## Prerequisites
This VM creation tool is tested to run on a Ubuntu 20.04 host. Virtualization needs to be enabled and qemu/kvm installed. 

##Clone VM creation tool
The tool is a lean set of files. Running the build script will download the Ubuntu image version (20.04 or 18.04) defined in the configuration file. To clone the repo, issue the following command on the host server cli and cd into the new directory:
```$ git clone https://github.com/kiedhub/ancillary_vm.git
$ cd ancillary_vm```

##Configuration
Before running the build script, some VM specific configurations need to be done. 

### Important configuration parameters
Chose a name for the virtual machine, that does not exist. If unsure check with ```virsh list --all```
vmName="ancillary"

### Network interfaces
####Data and service interfaces
In order to provide appropriate networking performance, interfaces will be passed through to the VM and they won't be available on the host system anymore. It is important to identify and chose the right interfaces. Generally one interface can be enough and all functions/services can be separated using VLANs. If a subscriber gets simulated and services are used, then it may make sense to use 2 interfaces, one for data and one for services.
Finding available interfaces can be done via
```sudo lshw -c network -businfo```

####Management interface
The interface connected to the management network is a virtual interface using virtio. There is no need to reserve a physical interface. It is important thought to think about the management connectivity. The current implementation makes use of a linux bridge for management. The easiest way to configure management to virtual machines is to connect the physical management interface on the host system to a virtual bridge and configure the host management IP address on the bridge.

The following example uses eno3 on the host server to connect to the management LAN. The interface does not have an IP address configured
```
$ ip a show dev eno3
4: eno3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq master management state UP group default qlen 1000
    link/ether e4:43:4b:24:65:b8 brd ff:ff:ff:ff:ff:ff
```

The physical interface is connect to the bridge named "management", so are the virtual interfaces (vnet4-7) of various other virtual machines.
```
$ brctl show management    
bridge name     bridge id               STP enabled     interfaces
management              8000.e4434b2465b8       no              eno3
                                                        vnet4
                                                        vnet5
                                                        vnet6
                                                        vnet7
```

The "management" brigde does have the ip address configured to it and the default route is set to the gateway of this network. Virtual machine network interfaces can be configured with IP address and gateway of the same management network (LAN).
```
$ ip a show dev management
16: management: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether e4:43:4b:24:65:b8 brd ff:ff:ff:ff:ff:ff
    inet 10.26.255.188/24 brd 10.26.255.255 scope global management
       valid_lft forever preferred_lft forever
    inet6 fe80::f412:8bff:fe58:a13/64 scope link 
       valid_lft forever preferred_lft forever

$ ip route show default
default via 10.26.255.1 dev management proto static
```



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


