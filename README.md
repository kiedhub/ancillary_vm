# Ancillary VM
## General
Ancillary_vm is a tool allowing to generate a virtual testing environment. It basically creates a Ubuntu based virtual machine and is meant to install all required tools to run a basic vBNG test plan or a customer demo. This includes subscriber connectivity (pppoe and ipoe for both IPv4 and IPv6), aaa server, tacacs_plus server, bgp-router environment, speedtest server, etc. 
It can also create a pkt-gen virtual maching in case this shall be run separately.

It is useful on servers in a lab were a testing envrionment may be required sporadically. The build and remove commands allow for easy creation and destroy without losing the virtual machine configuration. 

Following is a description on how to install, configure and build a virtual machine. 

## Prerequisites
This VM creation tool is tested to run on a Ubuntu 20.04 host. Virtualization needs to be enabled and qemu/kvm installed. Setting upa  virtual host server is outside of the scope of this doc.

## 1. Clone acillary_vm
The tool is a lean set of script files. Running the build script will download the Ubuntu image version (20.04 or 18.04) defined in the configuration file. 
Clone the repo by issuing the following command on the host server cli and cd into the new directory. If multiple virtual machines shall be created, it is possible to copy the configuration file and use one per virtual machine. This simplifies re-building and removing a virtual machine, because it is done by reading the configuration file.
```
$ git clone https://github.com/kiedhub/ancillary_vm.git
$ cd ancillary_vm
```

## 2. Check/prepare management connectivity
### Host system management network/bridge
The interface connected to the management network is a virtual interface using virtio. There is no need to reserve a physical interface for this. It is important thought to think about the management connectivity. The current implementation makes use of a linux bridge for management. The easiest way to configure management to virtual machines is to connect the physical management interface on the host system to a virtual bridge and configure the host management IP address on the bridge.

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
#### Create management bridge
The following netplan configuration shows the managemnet connectivity of the above example. Eno3 is connected to the management LAN, has no IP address configured, but is connected to the management bridge. The bridge itself gets the IP address configured to connect to the local network.
```
cat /etc/netplan/00-installer-config.yaml 
# This is the network config written by 'subiquity'
network:
  ethernets:
    eno3:
      dhcp4: false
  version: 2
  bridges:
    management:
      interfaces: [eno3]
      addresses:
        - 10.26.255.188/24
      gateway4: 10.26.255.1
      nameservers:
        addresses:
          - 8.8.8.8
          - 8.8.4.4
```
The configuration can get applied via 
```
sudo netplan apply
```

## 3. Adapt configuration
Before running the build script, some virtual machine specific configurations need to be done. Two sample configuration files are included that can be used as a basis for a new virtual machine, ancillary.conf and pkt-gen.conf. 
There are a view important/mandatory configuration parameters that needs to be looked at and adopted to the given environment and hardware.

### Virtual machine name and template
The configuration parameter vmName sets the unique name in the virtual environment. A unique name needs to be chosen, outherwise the build script will fail. In order to list all vm names that already exist use ```virsh list --all```. This provides a list of all vm definitions. The template defines the virtual machine profile and tools being installed, currently there are two profiles available, ancillary and pkt-gen. Default values
```
vmName="anc_vm"
vmTemplate="ancillary"
```
### Virtual machine management interface and ip address
The vm management interface defines the inteface name as shown in the virtual machine. For Ubuntu 20.04 this is ens3. It should be OK to leave the default value. If the installation fails, then it is worth to log into the created virtual machine via the console emulation and check on the name of the virtio inteface. This is the one to use as 'vmMgmtIf'.
```
virsh console <vmName>

lshw -c network -businfo
Bus info          Device      Class          Description
========================================================
pci@0000:00:03.0              network        Virtio network device
virtio@0          ens3        network        Ethernet interface
pci@0000:00:07.0  ens7        network        Ethernet Controller X710 for 10GbE 
pci@0000:00:08.0  ens8        network        Ethernet Controller X710 for 10GbE 
```

Set the IP address, gateway and dns server configuration of the virtual machine management interface. Currently only static configuration is supported. If dhcp shall be used, then this can be changed via console loging and changing the networking of the virtual machin (using netplan). Derault configuration parameters are
```
vmMgmtIf="ens3"
ipAddress="10.26.255.228"
ipPrefix="24"
gwAddress="10.26.255.1"
dnsServerList="8.8.8.8,8.8.4.4"
```
#### Add/Change the management network bridge name to the configuration file
```
vmMgmtBridge="management"
```
### Data and service interfaces
In order to provide appropriate networking performance, interfaces connected to the SUT (e.g. MSR2400) will be passed through to the VM and they won't be available on the host system anymore. It is important to identify and chose the right interfaces. Generally one interface can be enough and all functions/services can be separated using VLANs. If a subscriber gets simulated and services are used, then it may make sense to use 2 interfaces, one for data and one for services.
Finding available interfaces can be done via
```sudo lshw -c network -businfo```
#### Add the interfaces to the configuration file
vmDevlist="enp216s0f1, enp216s0f2"

### Virtual machine settings
It is possible to pin CPUs to the VM via ```vmCpuSet```. This makes most sense if those are isolated, a check via ```cat /proc/cmdline``` helps to clarify on it. 

Setting ```vmCpuSet=""``` does not strictly assign CPUs to the VM and leaves the assignment to KVM/qemu. Be aware the that CPUs may be shared across multiple VMs which may degrade the VM's performance. This is currently not supported.

Memory and vmVcpus should be set according to the services that will be enabled on the VM. 

## 4. Build virtual machine
Once configuration is applied, the vm can be built using its configuration file name
```
sudo bash
./build_vm ancillary_vm.conf
```
## 5. Remove virtual machine
Removing a virtual machine can be done the same way as building. The configuration file name is used to destroy, undefine and delete the virtual machine and its qcow2 file. Because of this it is recommended to use a separate configuration file for each newvirtual machine.
```
sudo bash
./remove ancillary_vm.conf
```

## Virtual machine login credentials
Default username/password: casa/casa

Since docker requires root privileges, the login scrip elevates user case at login. 


