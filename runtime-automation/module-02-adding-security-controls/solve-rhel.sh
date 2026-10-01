#!/bin/sh
# Source lab environment variables
. /etc/profile.d/lab.sh

echo "Building and deploying security VM..." >> /tmp/progress.log

cd ~/bootc-base

# Add security packages if not already present
if ! grep -q 'Security and Hardening' Containerfile; then
    cat >> Containerfile <<'EOF'

# Security and Hardening
RUN dnf -y install audit fapolicyd openscap-utils scap-security-guide setroubleshoot-server

RUN systemctl enable fapolicyd
EOF
fi

# Create tailored SCAP policy if it doesn't exist
if [ ! -f cis_server_l1_customized.xml ]; then
    autotailor --unselect xccdf_org.ssgproject.content_rule_sshd_disable_root_login \
      --new-profile-id cis_server_l1_customized \
      --output cis_server_l1_customized.xml \
      /usr/share/xml/scap/ssg/content/ssg-rhel10-ds.xml cis_server_l1 2>&1 >> /tmp/progress.log
fi

# Add SCAP remediation to Containerfile if not already present
if ! grep -q 'oscap-im' Containerfile; then
    cat >> Containerfile <<'EOF'

LABEL profile="CIS Server Level 1 base image"
ENV profileID=cis_server_l1_customized

COPY $profileID.xml /tmp/$profileID.xml
RUN oscap-im --profile $profileID --tailoring-file /tmp/$profileID.xml /usr/share/xml/scap/ssg/content/ssg-rhel10-ds.xml
EOF
fi

# Build and push the hardened image
podman build --file Containerfile --tag registry-${GUID}.${DOMAIN}/base 2>&1 >> /tmp/progress.log
podman push registry-${GUID}.${DOMAIN}/base 2>&1 >> /tmp/progress.log

# Find SSH key
KEY=$(ls /root/.ssh/*key 2>/dev/null | head -1)

# Wait for VM to be accessible
sleep 10

# Apply bootc update on the VM to get the hardened image
ssh -i "$KEY" -o StrictHostKeyChecking=no -o ConnectTimeout=30 core@bootc-vm 'sudo bootc update --apply' 2>&1 >> /tmp/progress.log

# Reboot the VM to apply changes
ssh -i "$KEY" -o StrictHostKeyChecking=no -o ConnectTimeout=10 core@bootc-vm 'sudo systemctl reboot' 2>&1 >> /tmp/progress.log || true

# Wait for reboot
sleep 30

echo "Security-hardened VM deployed" >> /tmp/progress.log
