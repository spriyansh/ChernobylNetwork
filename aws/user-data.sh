#!/bin/bash

# Install SDKMAN
curl -s "https://get.sdkman.io" | bash
export SDKMAN_DIR="/home/ec2-user/.sdkman"
export PATH="$SDKMAN_DIR/bin:$PATH"
source "$SDKMAN_DIR/bin/sdkman-init.sh"

# Install git 
yum install -y git

# Install tmux
yum install -y tmux

# Install Java using SDKMAN
su - ec2-user -c "curl -s https://get.sdkman.io | bash"
su - ec2-user -c "source /home/ec2-user/.sdkman/bin/sdkman-init.sh && sdk install java 17.0.10-tem && sdk default java 17.0.10-tem"

# Install Nextflow
su - ec2-user -c "curl -s https://get.nextflow.io | bash && mkdir -p /home/ec2-user/.local/bin && mv nextflow /home/ec2-user/.local/bin && chmod +x /home/ec2-user/.local/bin/nextflow"

# Update PATH for ec2-user
echo 'export PATH=$PATH:/home/ec2-user/.local/bin/' >> /home/ec2-user/.bashrc
echo 'export SDKMAN_DIR=/home/ec2-user/.sdkman' >> /home/ec2-user/.bashrc

# Install Miniconda
curl -fsSL https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -o /home/ec2-user/miniconda.sh
chmod +x /home/ec2-user/miniconda.sh
su - ec2-user -c "bash /home/ec2-user/miniconda.sh -b -p /home/ec2-user/miniconda"

# Update PATH for Miniconda
echo 'export PATH=/home/ec2-user/miniconda/bin:$PATH' >> /home/ec2-user/.bashrc
su - ec2-user -c "source /home/ec2-user/.bashrc && conda init bash"

# Verify Miniconda and Nextflow Installation
su - ec2-user -c "source /home/ec2-user/.bashrc && conda --version"
su - ec2-user -c "source /home/ec2-user/.bashrc && nextflow info"