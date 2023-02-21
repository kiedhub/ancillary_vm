#!/bin/bash

# cloud init library:
#   create_cloud_init() calls create_ancillary_vm 
#   create_ancillary_vm() creates the docker VM with all containerized services
#   create_pktgen_vm() creates the docker VM with all containerized services
#   create_cloud_network_config()
#   create_seed_image()

[ $DEBUG = true ] && echo "Including ${BASH_SOURCE[0]}"

create_cloud_init()
{
  [ $DEBUG = true ] && echo "${FUNCNAME[0]}"
  case $vmTemplate in
    ancillary)
      create_ancillary_vm
      ;;
    pkt-gen)
      create_pktgen_vm
      ;;
    *)
      echo "Template not found"
      exit
      ;;
  esac
}

create_ancillary_vm()
{
  [ $DEBUG = true ] && echo "${FUNCNAME[0]}"

  [ -e $BUILD_DIR/$cloudInitFileName ] && echo "Removing existing file $cloudInitFileName"; rm -f $BUILD_DIR/$cloudInitFileName;
  echo "Creating $BUILD_DIR/$cloudInitFileName"

  echo "#cloud-config
  hostname: $vmHostname 
  manage_etc_hosts: true
  users:
    - name: $vmUser
      sudo: ALL=(ALL) NOPASSWD:ALL
      groups: vmUsers, admin
      home: /home/$vmUser
      shell: /bin/bash
      lock_passwd: false
      ssh-authorized-keys:
        - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC+ncGBon+AaKMWvAD0bQL+GnE1M3GKa8SOHDogd/ymAH2hTDRzCVgizFqy3mwGb194Iy1fogPov9bUgyPyUkqneYRCxjB0KXkeNBUsaUymBRqCZVsWQepCXGT3qXZ9RFVmN43zp+67ACSkc9XFecsXgEUR8GAOVsGFl17415HtYRPk8lre2+jaAqzsMfp5NJ89m9vPlvhvTPBvxheUz+XjCnYeoqByDlwk6IXjyb6D2zysTUuU/MKN277MUxydrOyuOgudTAcXXpcSg17Mv4bVisXPQnHY08qe7Buu2FLUsfq8ubv4Rrgal9JzuP1v3o/nEmRprWbinbidgHfs6tlF ralf
        - $sshPubKey
  # only cert auth via ssh (console access can still login)
  ssh_pwauth: $vmSshPermitPasswordAuth 
  disable_root: false
  chpasswd:
    list: |
       $vmUser:$vmUserPwd
       root:$vmUserPwd
    expire: False
  
#  package_update: true
#  package_upgrade: true

  packages:
    - apt-transport-https
    - ca-certificates
    - curl
    - gnupg
    - lsb-release
    - unzip
    - net-tools
    - make
    - snmp
    - snmp-mibs-downloader
    - snmpd
    - traceroute
    - net-tools
    - pppoe

  runcmd:
    - curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    - echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"| sudo tee /etc/apt/sources.list.d/docker.list >/dev/null 
    - sudo apt-get update
    - sudo apt-get -y install docker.io docker-compose
    - sudo docker pull rsattler/bgp-router
    - sudo docker pull rsattler/aaa-server
    - sudo docker pull rsattler/speedtest
    - sudo docker pull rsattler/tacacs_plus
    - cd /root ; curl -L -O https://github.com/kiedhub/msr_ancillary/archive/refs/heads/main.zip ; unzip main.zip ; rm -f main.zip
    - mkdir -p /root/.ssh/ ; cp /home/$vmUser/.ssh/authorized_keys /root/.ssh/
    - echo "sudo su" >> /home/$vmUser/.bashrc ; echo "cd ~" >> /home/$vmUser/.bashrc
    - echo "cd ~" >> /root/.bashrc
    - echo "msr_ancillary-main" >> /root/.bashrc

  # written to /var/log/cloud-init-output.log
  final_message: \"The system is finally up, after $UPTIME seconds\"" > $BUILD_DIR/$cloudInitFileName
}

create_pktgen_vm()
{
  [ $DEBUG = true ] && echo "${FUNCNAME[0]}"

  [ -e $BUILD_DIR/$cloudInitFileName ] && echo "Removing existing file $cloudInitFileName"; rm -f $BUILD_DIR/$cloudInitFileName;
  echo "Creating $BUILD_DIR/$cloudInitFileName"

  echo "#cloud-config
  hostname: $vmHostname 
  manage_etc_hosts: true
  users:
    - name: $vmUser
      sudo: ALL=(ALL) NOPASSWD:ALL
      groups: vmUsers, admin
      home: /home/$vmUser
      shell: /bin/bash
      lock_passwd: false
      ssh-authorized-keys:
        - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC+ncGBon+AaKMWvAD0bQL+GnE1M3GKa8SOHDogd/ymAH2hTDRzCVgizFqy3mwGb194Iy1fogPov9bUgyPyUkqneYRCxjB0KXkeNBUsaUymBRqCZVsWQepCXGT3qXZ9RFVmN43zp+67ACSkc9XFecsXgEUR8GAOVsGFl17415HtYRPk8lre2+jaAqzsMfp5NJ89m9vPlvhvTPBvxheUz+XjCnYeoqByDlwk6IXjyb6D2zysTUuU/MKN277MUxydrOyuOgudTAcXXpcSg17Mv4bVisXPQnHY08qe7Buu2FLUsfq8ubv4Rrgal9JzuP1v3o/nEmRprWbinbidgHfs6tlF ralf
        - $sshPubKey
  # only cert auth via ssh (console access can still login)
  ssh_pwauth: $vmSshPermitPasswordAuth 
  disable_root: false
  chpasswd:
    list: |
       $vmUser:$vmUserPwd
       root:$vmUserPwd
    expire: False
  
  package_update: true
  package_upgrade: true

  packages:
    - snmp
    - snmp-mibs-downloader
    - snmpd
    - traceroute
    - net-tools
    - make
    ## anc vm
    #- apt-transport-https
    #- ca-certificates
    #- curl
    #- gnupg
    #- lsb-release
    - unzip
    #- net-tools
    - pppoe

  runcmd:
    - download-mibs
    # anc vm
    #- curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    #- echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"| sudo tee /etc/apt/sources.list.d/docker.list >/dev/null 
    #- sudo apt-get update
    #- sudo apt-get -y install docker.io docker-compose
    #- sudo docker pull rsattler/bgp-router
    #- sudo docker pull rsattler/aaa-server
    #- sudo docker pull rsattler/speedtest
    - curl -L -O https://github.com/kiedhub/msr_ancillary/archive/refs/heads/main.zip
    - unzip main.zip
    - rm -f main.zip
    - cp -R msr_ancillary-main/subscriber/* msr_ancillary-main/functions.sh msr_ancillary-main/ancillary.conf .
    - rm -rf msr_ancillary-main pkt-gen


  # written to /var/log/cloud-init-output.log
  final_message: \"The system is finally up, after $UPTIME seconds\"" > $BUILD_DIR/$cloudInitFileName
}

create_cloud_network_config()
{
  [ $DEBUG = true ] && echo "${FUNCNAME[0]}"

  if [ -e $BUILD_DIR/$netConfFileName ]; then
    echo "Removing existing file $netConfFileName" 
    rm -f $BUILD_DIR/$netConfFileName
  fi
  
  [ $DEBUG = true ] && echo "  Creating $BUILD_DIR/$netConfFileName"

  # Currently only static configuration is supported, a later version may be able to use dhcp
  echo "version: 2
ethernets:
  $vmMgmtIf:
    addresses: [$ipAddress/$ipPrefix]
    gateway4: $gwAddress
    nameservers:
      addresses: [$dnsServerList]" > $BUILD_DIR/$netConfFileName
}

create_seed_image()
{
  [ $DEBUG = true ] && echo "${FUNCNAME[0]}"
  
  cd $BUILD_DIR

  # check for configuration files
  [ $DEBUG = true ] && echo "  Checking cloud filename: $cloudInitFileName "

  if [ ! -e $cloudInitFileName ]; then 
    echo "File $cloudInitFileName does not exist, exiting" 
    exit 1
  fi

  [ $DEBUG = true ] && echo "  Checking netconf"
  if [ ! -e $netConfFileName ]; then 
    echo "File $netConfFileName does not exist, exiting" 
    exit 1
  fi

  [ $DEBUG = true ] && echo "  Checking for configuration file -> OK"
  
  # remove old file
  if [ -e $seedImageName ]; then
    echo "Removing existing file $seedImageName"
    rm -f ./$seedImageName
  fi

  echo "Creating $BUILD_DIR/$seedImageName"

  cloud-localds -v --network-config=$netConfFileName $seedImageName $cloudInitFileName

  if [ ! -e $seedImageName ]; then 
    echo "Failed to create $seedImageName, exiting" 
    exit 1
  fi

  cd $SCRIPT_DIR
}
