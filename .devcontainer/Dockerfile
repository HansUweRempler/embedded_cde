# Use the base image from devcontainer.json
FROM mcr.microsoft.com/devcontainers/base:jammy

# Add any additional setup or dependencies here
# For example, installing additional packages
# RUN apt-get update && apt-get install -y <package-name>
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
        # build-essential \
        # cmake \
        # git \
        #gcc-arm-none-eabi \
        usbutils \
        stlink-tools \
        kmod \
    && apt-get -y install \
        linux-tools-$(uname -r) \
        linux-modules-$(uname -r) \
        linux-modules-extra-$(uname -r)

# Clone the FreeRTOS-Kernel repository
# RUN git clone https://github.com/FreeRTOS/FreeRTOS-Kernel.git /usr/local/src/FreeRTOS-Kernel

# Run the specified commands
RUN depmod \
    && modprobe usbip-host \
    && modprobe vhci-hcd \
    && lsmod | grep usb

# Set up any environment variables
# ENV MY_VAR=my_value

# Copy any necessary files
# COPY . /path/in/container

# Set the working directory
# WORKDIR /path/in/container

# Expose any necessary ports
# EXPOSE 8080

# Define the command to run when the container starts
# CMD ["executable", "param1", "param2"]
