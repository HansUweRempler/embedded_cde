# Always Ready to Code! Even Embedded...
Embedded Cloud Development Environment (CDE)

Sources: mAIbros PC ~/kvm_vms \
Repo new: https://github.com/HansUweRempler/embedded_cde
Repo old: https://github.com/HansUweRempler/STM32

# Infrastructure
Architecture: https://miro.com/app/board/uXjVLpRwctA=/ \
Available Resources: 16CPUs, 32768MB, 2000GB

## Automation Script
Summary of the below sections in one script `./infrastructure_kvm/install_kvms.sh`. It modifies the cloud-init template files and runs multiple VM installations, see [Cloud](#cloud). The script has still some hard-coded values inside, e.g., the installation ISO is `ubuntu-24.04.1-live-server-amd64.iso`, download from https://releases.ubuntu.com/noble/.

The required packages can be found in the [Packages](#packages) section.

The VM network config needs to be completed beforehand if a bridge network shall be used, see [Network](#network). The 

## KVM Virtualization
### Packages
Install necessary KVM hypervisor, libvirt and tools packages:
```
sudo apt update
sudo apt install -y \
qemu-system-x86 \
libvirt-daemon-system \
libvirt-clients \
bridge-utils \
virtinst \
cloud-image-utils
```

### Network 
Add a bridge to the network config such that the VMs get own IPs. In Lubuntu (mAIbros installation) the network is managed via the tool NetworkManager. It is not using netplan or such.

**Host OS bridge** links a physical interface `enp6s0` to a new bridge network interface `br0`. The `eth0` network interface is then obsolete.
```
nmcli con add type bridge ifname br0 con-name br0
nmcli con add type bridge-slave ifname enp6s0 master br0
nmcli con modify br0 bridge.stp no
nmcli con down "Wired connection 1"
nmcli con up br0
sudo systemctl restart NetworkManager.service

nmcli con show
ip a s br0
```

The **network configuration** is in the `./infrastructure_kvm/br0-net.xml` and started via
```
virsh net-define br0-net.xml
virsh net-start br0-net
virsh net-autostart br0-net
virsh net-list --all
```

Additional rights are required for `qemu-bridge-helper` in order to access the host OS bridge.
```
sudo setcap cap_net_admin+ep /usr/lib/qemu/qemu-bridge-helper
getcap /usr/lib/qemu/qemu-bridge-helper
```

**KVM virtual machine installation** command:
```
virt-install \
  --name maibrosvm00 \
  --vcpus 4 \
  --memory 8192 \
  --disk path=maibrosvm00.qcow2,format=qcow2,size=100 \
  --disk path=cloud-init.iso,device=cdrom \
  --cdrom ubuntu-24.04.1-live-server-amd64.iso \
  --os-variant ubuntu24.04 \
  --graphics vnc \
  --console pty,target_type=serial \
  --network network=br0-net
```

Use [virt-manager](https://virt-manager.org/) or CLI commands to shutdown and start the VM:
```
virsh shutdown maibrosvm00
virsh start maibrosvm00
```

## Cloud
**Cloud-init** is a general mechanism for unattended Linux installations for cloud provisioning. Its basis are config files `user-data` and `meta-data` which become part of an ISO installation file. This ISO file is then mounted by, e.g, KVM (virt-install) as `CIDATA`. Its content is used to customize the installation.

**Autoinstall** is the Ubuntu mechanism for unattended, automatic installation of an Ubuntu distribution. Its basis is a single config file that is used during the installation. This config can alternatively be used inside cloud-init files. The latest cloud-init version supports a dedicated `autoinstall:` section, see template `./infrastructure_kvm/user-data.template`.

The template `meta-data` is empty. Every herein required meta data is already in `user-data` due to the use of the Ubuntu autoinstallation mechanism.

# Kubernetes
A Kubernetes (in short "k8s") cluster can be installed manually with a lot of effort or pre-configured via some distros. K3s and k0s are Kubernetes distros, while Rancher is a management platform (with web ui) that can control these and other Kubernetes clusters. Rancher comes with a K3s distro under the hood.

## Rancher
Rancher comes as a Docker container. It is started inside one of above VMs - not (!) on the host machine. For this, Docker needs to be installed on the corresponding VM.
```
sudo apt update
sudo apt install docker.io

# no good if ports 80/443 are already in use, e.g., by Mattermost/NGINX 
sudo docker run --privileged -d --restart=unless-stopped -p 80:80 -p 443:443 rancher/rancher

# alternative ports
sudo docker run --privileged -d --name rancher-server --restart=unless-stopped -p 81:80 -p 444:443 rancher/rancher
```

# Developer's PC
Run the following on your developer PC. Access the Coder web UI control plane, use a Coder template to create a workspace config. Start the workspace, start therein your IDE, e.g. VS Code server - can be access via SSH tunnel or via web interface (VS Code runs in the browser).

## Linux
Install USBIP server package to bind a USB device. The USBIP server provides the USB device access via port 3240.
```
# Install USBIP 
sudo apt install hwdata linux-tools-generic

#Load USBIP server
sudo modprobe usbip-host
sudo modprobe vhci_hcd
sudo usbipd --daemon

# List local USB devices
lsusb
usbip list --local

# Bind USB device to USBIP server
sudo usbip bind -b 1-3
```

Install Coder package (and its command line tool) to communicate with the Coder server. The Coder command line tool then gets the config data from the server after login. This is helpful for the SSH names and credentials.
```
# Local host coder **CLI install**
curl -L https://coder.com/install.sh | sh

# Login to Coder server
coder login http://192.168.178.186:32580

# Config local SSH settings
coder config-ssh
```

Finally, login and port-forward local USBIP server to the Coder workspace that shall access the USB device (via USPIP client):
```
ssh -R 2001:localhost:3240  coder.emerald-grasshopper-50.main
```

# Attach the remote USB device
```
# Optional check if tunneled port-forwaring worked; requires `apt install netcat-openbsd`
nc -z localhost 2001 || echo "no tunnel open"

sudo usbip --tcp-port 2001 list -r localhost
sudo usbip --tcp-port 2001 attach -r localhost -b 2-1
lsusb
sudo st-flash reset
```


## Windows

Install Windows USBIPD. Go to the latest release page for the usbipd-win project: https://github.com/dorssel/usbipd-win/releases. Select the .msi file, which will download the installer. Run the downloaded usbipd-win_x.msi installer file. Enable USB device sharing. Connect STM32 dev kit via USB, run a PowerShell with admin rights.
```
PS C:\WINDOWS\system32> usbipd.exe list
Connected:
BUSID  VID:PID    DEVICE                                                        STATE
2-1    0483:374b  ST-Link Debug, USB Mass Storage Device, USB Serial Device...  Not shared
[...]

PS C:\WINDOWS\system32> usbipd.exe bind -b 2-1
PS C:\WINDOWS\system32> usbipd.exe list
Connected:
BUSID  VID:PID    DEVICE                                                        STATE
2-1    0483:374b  ST-Link Debug, USB Mass Storage Device, USB Serial Device...  Shared
[...]
```

Install Coder package (and its command line tool) to communicate with the Coder server, see https://coder.com/docs/install. The Coder command line tool then gets the config data from the server after login. This is helpful for the SSH names and credentials.
```
# Local host coder **CLI install**
PS C:\WINDOWS\system32> winget install Coder.Coder

# Login to Coder server
PS C:\Program Files\Coder\bin> .\coder.exe login http://192.168.178.186:32580

# Config local SSH settings
PS C:\Program Files\Coder\bin> .\coder.exe config-ssh
```

Finally, login and port-forward local USBIP server to the Coder workspace that shall access the USB device (via USPIP client).
```
PS C:\Program Files\Coder\bin> ssh -R 2001:localhost:3240 coder.emerald-grasshopper-50.main
```

# Attach the remote USB device
```
# Optional check if tunneled port-forwaring worked; requires `apt install netcat-openbsd`
nc -z localhost 2001 || echo "no tunnel open"

sudo usbip --tcp-port 2001 list -r localhost
sudo usbip --tcp-port 2001 attach -r localhost -b 2-1
lsusb
sudo st-flash reset
```

## Docker
Optional section to test USBIP.

This section tests the manual process to use privileged Docker container. This container can then access the host's kernel to load virtual USB kernel modules. The USBIP tool can then attach a USB device from USBIP server to the virtual USB device kernel module. This device is then addded to the USB device tree.

The dev PC start the USPIP server and binds the USB device. The target PC starts a privileged Docker container. Therein, a SSH server is started. Then, a SSH tunnel (including port forwarding) from dev PC to the Docker container that runs on the target PC. In that login (inside the Docker container) the necessary USBIP kernel modules and tools are installed. The USBIP tool can then attach the USB device to the port forwarded SSH tunnel.

**1. Step:** Load USBIP server and bind a USB device to it
```
sudo modprobe usbip-host
sudo usbipd --daemon
sudo usbip bind -b 1-3
```

**2. Step:** Ssh to remote machine where the Docker container will run
```
ssh ansible@maibrosvm01
```

**3. Step:** Start privileged Docker container and port forward ssh from remote machine into it. This is somehow like starting/deploying a workspace.
```
sudo docker run -p 52022:22 -t -i --privileged -v /dev/bus/usb:/dev/bus/usb ubuntu bash
```

**4. Step:** Get into the docker container and prepare ssh server (as root)
```
apt update
apt install openssh-server net-tools nano
passwd
nano /etc/ssh/sshd_config
+++ PermitRootLogin yes
service ssh start
```

**5. Step:** Ssh from host into the docker inside remote machine. Via Coder (or Gitpod or ...) this is typically managed by the command line tool.
```
ssh -p 52022 -R 2001:localhost:3240 root@maibrosvm01
```

**6. Step:** Inside the Container to the USBIP tool stuff (as root)
```
apt install usbutils \
stlink-tools \
kmod \
linux-tools-$(uname -r) \
linux-modules-$(uname -r) \
linux-modules-extra-$(uname -r)

depmod
modprobe vhci-hcd
lsmod | grep usb
usbip --tcp-port 2001 list -r localhost
usbip --tcp-port 2001 attach -r localhost -b 1-3
lsusb
st-flash reset
```

# Coder
https://coder.com/docs/install/kubernetes \
https://coder.com/blog/running-coder-in-a-k3s-cluster-self-hosted

## Installation
For a Kubernetes installation of Coder use the package manager Helm. The Coder control plane is then an application that runs as a regular Kubernetes pod. Edit the `values.yaml` from https://coder.com/docs/install/kubernetes#4-install-coder-with-helm . **Important:** use a non-ssl URL if no valid certificate available (e.g. from Let'sEncrypt).
```
    # If you're just trying Coder, access the dashboard via the service IP.
    - name: CODER_ACCESS_URL
      value: "http://192.168.178.186"
```
TODO: Need to double check. I'm unsure, if `allowPrivilegedEscalation` is set to run the Coder control plane or the workspace pods as `privileged`. The Coder control plane doesn't need this additional rights. And it is also not needed for workspace pods if the Coder `envbuilder` is used. But maybe it's required for the workspace Kubernetes pod or the Kubernetes VM deployment. It is required for the USBIP tools stuff to attach to the tunneled USB device, see [Docker](#docker).
```
  securityContext:
    allowPrivilegeEscalation: true
```

* coder url: http://192.168.178.186:32580/setup
* credentials:
	* admin
	* admin test
	* keiner@uni.de
	* xxx

## Devcontainer
Run Coder workspaces as container and use the devcontainer mechanism to set it up.
The Coder template can be found in `./template_coder/kubeDevContainer`. It can be used via
```
cd template_coder/kubeDevContainer
coder templates push -d .
```

In `.devcontainer/Dockerfile` includes the requires stuff for USBIP client. This is similar to the [Docker](#docker) test.

**Devcontainers (Kubernetes) Coder template error** can be resolved via additional Cluster Role and Cluster Role Binding to enable coder to create persistentVolumeClaims in default namespace:
https://github.com/coder/coder/discussions/16175

## Kubernetes
Run Coder workspaces as Kubernetes pods.
The Coder template can be found in `./template_coder/kubePod`.

### Lösung Kubernetes (Coder)
Ein Kubernetes Pod ist ein Container, der von Kubernetes gestartet und verwaltet wird, z.B. auf welchem Node der (Pod) Workload ausgeführt wird.

Coder kann solche Kubernetes Pods auch selbst direkt starten. Dafür gibt es ein "Kubernetes (Deployment)" Template.

Coder kann auch Docker Container selbst direkt starten. Wenn Coder nicht selbst auch als Pod in Kubernetes läuft, sonder als Service direkt ausgeführt wird. Zusätzlich muss dann auf den ausführenden VMs (dort wo auch ein Coder Agent läuft) Docker laufen und ein "Coder" User entsprechende Docker Rechte haben.

Es gibt auch ein Coder Template mit dem Coder ein Kubernetes Pod so startet, dass der Pod als Devcontainer gestartet wird. Also ein Devcontainer mit einem Pod als Container.
* Dieser Kubernetes Pod ist ein Container von Coder "ghcr.io/coder/envbuilder:latest". Er könnte auch mit einem `docker pull ghcr.io/coder/envbuilder:1.1.0` gezogen und gestartet werden. Wenn er läuft, fummelt er entweder
	* einen Kubernetes Pod mit einen Devcontainer, der im Repo via `.devcontainer` konfiguriert wird

#### step 1
See [Installation](#installation).

#### step 2
Das Coder Template für "Kubernetes (Deployment)" anpassen, um
* die darauf basierenden Pods privileged zu starten:
```
[...]
        container {
          name              = "dev"
          image             = "codercom/enterprise-base:ubuntu"
          image_pull_policy = "Always"
          command           = ["sh", "-c", coder_agent.main.init_script]
          security_context {
            run_as_user = "1000"
            privileged = true
          }
[...]
```

* den Pod mit `/dev/bus/usb` und `/sys` schreibend zu starten
 ```
volume_mount {
	mount_path = "/dev/bus/usb"
	name = "usb"
	read_only = false
}
volume_mount {
	mount_path = "/sys"
	name = "sys"
	read_only = false
}
```

```
volume {
	name = "usb"
	host_path {
		path = "/dev/bus/usb"
		type = "Directory"
	}
}
volume {
	name = "sys"
	host_path {
		path = "/sys"
		type = "Directory"
	}
}
```

#### step 3
Dann via SSH-Tunnel in den Kubernetes Pod rein. Coder Workspace, der auf dem Template oben basiert, muss vorher gestartet worden sein.
```
ssh -R 2001:localhost:3240 coder.androiddev.main
```

Install necessary packages. This is only needed for Coder Kubernetes pod deployment because no dev container setup takes care of this (like configured in a `.devcontainer` dir).
```
apt update
apt install -y usbutils \
stlink-tools \
kmod \
linux-tools-$(uname -r) \
linux-modules-$(uname -r) \
linux-modules-extra-$(uname -r)
```

Load kernel modules and attach the remote USBIP tunnelled USB device.
```
depmod
modprobe vhci-hcd
lsmod | grep usb
usbip --tcp-port 2001 list -r localhost
usbip --tcp-port 2001 attach -r localhost -b 1-3
lsusb
st-flash reset
```

