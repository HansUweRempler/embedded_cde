# Use the base image from devcontainer.json
#FROM mcr.microsoft.com/devcontainers/base:jammy
FROM ubuntu:latest

# Set the environment variable to non-interactive
ENV DEBIAN_FRONTEND=noninteractive

# Update the package list
RUN apt update

# Install coder agent requirements
RUN apt -y install \
        curl \        
        wget

# Install additional packages
RUN apt -y install \
        usbutils \
        stlink-tools \
        kmod

# Install tools for the Linux kernel and kernel modules
RUN apt -y install \
        linux-tools-$(uname -r) \
        linux-modules-$(uname -r) \
        linux-modules-extra-$(uname -r)

# Install embedded build toolchain
# RUN apt-get -y install --no-install-recommends \
#         build-essential \
#         cmake \
#         git \
#         gcc-arm-none-eabi

# Clone the FreeRTOS-Kernel repository
# RUN git clone https://github.com/FreeRTOS/FreeRTOS-Kernel.git /usr/local/src/FreeRTOS-Kernel

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
