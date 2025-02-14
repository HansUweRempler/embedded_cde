#!/bin/bash

# Define your arrays
VMNO=("02" "03")
VCPU=(2 2)
VRAM=(4096 4096)
SIZE=(100 100)

# Validate array lengths
if [[ ${#VMNO[@]} -ne ${#VCPU[@]} ]] || \
   [[ ${#VMNO[@]} -ne ${#VRAM[@]} ]] || \
   [[ ${#VMNO[@]} -ne ${#SIZE[@]} ]]; then
    echo "Error: Arrays must have the same length"
    exit 1
fi

# Loop through the arrays
for ((i=0; i<${#VMNO[@]}; i++)); do
	# Echo the variables
	echo "Entry $((i+1)): VMNO=${VMNO[i]}, VCPU=${VCPU[i]}, VRAM=${VRAM[i]}, SIZE=${SIZE[i]}"
done

read -p "Existing files will be overwritten, are you sure to continue? (Y/N) - default [N]: " choice
case "${choice:=N}" in
    [Yy]* ) 
        echo "Proceeding with overwrite..."
        # Your code for overwriting goes here
        ;;
    * ) 
        echo "Operation cancelled"
        exit 1
        ;;
esac

# Loop through the arrays
for ((i=0; i<${#VMNO[@]}; i++)); do

	# Echo
	echo "---"
	echo "Creating VM $((i+1)): VMNO=${VMNO[i]}, VCPU=${VCPU[i]}, VRAM=${VRAM[i]}, SIZE=${SIZE[i]}"

	# Cloud-init files user-data meta-data
	echo "sed -e \"s/hostname: ubu24-template/hostname: maibrosvm${VMNO[i]}/\" user-data.template > user-data"
	sed -e "s/hostname: ubu24-template/hostname: maibrosvm${VMNO[i]}/" user-data.template > user-data

	# Cloud-init ISO file
	echo "cloud-localds ubuntu-cloud-init${VMNO[i]}.iso user-data meta-data"
	cloud-localds ubuntu-cloud-init${VMNO[i]}.iso user-data meta-data

	# Virtual machines installation
	echo "virt-install --quiet --name maibrosvm${VMNO[i]} --vcpus ${VCPU[i]} --memory ${VRAM[i]} --disk path=maibrosvm${VMNO[i]}.qcow2,format=qcow2,size=${SIZE[i]} --disk path=ubuntu-cloud-init${VMNO[i]}.iso,device=cdrom --cdrom ubuntu-24.04.1-live-server-amd64.iso --os-variant ubuntu24.04 --graphics none --console pty,target_type=serial --network network=br0-net"
	nohup virt-install \
	  --quiet \
	  --name maibrosvm${VMNO[i]} \
	  --vcpus ${VCPU[i]} \
	  --memory ${VRAM[i]} \
	  --disk path=maibrosvm${VMNO[i]}.qcow2,format=qcow2,size=${SIZE[i]} \
	  --disk path=ubuntu-cloud-init${VMNO[i]}.iso,device=cdrom \
	  --cdrom ubuntu-24.04.1-live-server-amd64.iso \
	  --os-variant ubuntu24.04 \
	  --graphics none \
	  --console pty,target_type=serial \
	  --network network=br0-net \
	  &

	# Sleep to not start all installations at the same time
	sleep 10
done
