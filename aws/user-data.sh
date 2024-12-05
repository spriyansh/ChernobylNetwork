#!/bin/bash

# Install Nextflow in EC2 on first reboot

# Install SDKMAN
curl -s "https://get.sdkman.io" | bash
export SDKMAN_DIR="/home/ec2-user/.sdkman"
export PATH="$SDKMAN_DIR/bin:$PATH"
source "$SDKMAN_DIR/bin/sdkman-init.sh"

# Install Java using SDKMAN
su - ec2-user -c "curl -s https://get.sdkman.io | bash"
su - ec2-user -c "source /home/ec2-user/.sdkman/bin/sdkman-init.sh && sdk install java 17.0.10-tem && sdk default java 17.0.10-tem"

# Download and Install Nextflow
su - ec2-user -c "curl -s https://get.nextflow.io | bash && mkdir -p /home/ec2-user/.local/bin && mv nextflow /home/ec2-user/.local/bin && chmod +x /home/ec2-user/.local/bin/nextflow"

# Update PATH for ec2-user
echo 'export PATH=$PATH:/home/ec2-user/.local/bin/' >> /home/ec2-user/.bashrc
echo 'export SDKMAN_DIR=/home/ec2-user/.sdkman' >> /home/ec2-user/.bashrc

# Verify Installation
su - ec2-user -c "source /home/ec2-user/.bashrc && nextflow info"
