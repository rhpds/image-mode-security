#!/bin/sh
echo "Building and deploying security VM..." >> /tmp/progress.log

CONTAINERFILE="~/bootc-base/Containerfile"
MARKER="RUN systemctl mask bootc-fetch-apply-updates.timer"

sed -i "/^${MARKER}\$/a\\
\\
RUN dnf -y install audit fapolicyd openscap-utils scap-security-guide setroubleshoot-server\\
\\
RUN systemctl enable fapolicyd\\
\\
LABEL profile=\"CIS Server Level 1 base image\"\\
ENV profileID=cis_server_l1_customized\\
\\
COPY \$profileID.xml /tmp/\$profileID.xml\\
RUN oscap-im --profile \$profileID --tailoring-file /tmp/\$profileID.xml /usr/share/xml/scap/ssg/content/ssg-rhel10-ds.xml" "$CONTAINERFILE"

cd ~/bootc-base

autotailor --unselect xccdf_org.ssgproject.content_rule_sshd_disable_root_login \
  --new-profile-id cis_server_l1_customized \
  --output cis_server_l1_customized.xml \
  /usr/share/xml/scap/ssg/content/ssg-rhel10-ds.xml cis_server_l1

podman build --file Containerfile --tag registry-${GUID}.${DOMAIN}/base 2>&1 >> /tmp/progress.log
podman push registry-${GUID}.${DOMAIN}/base 2>&1 >> /tmp/progress.log

cd ~
podman run --rm --privileged --security-opt label=type:unconfined_t \
  --volume ./config.toml:/config.toml \
  --volume /var/lib/containers/storage:/var/lib/containers/storage \
  --volume .:/output \
  registry.redhat.io/rhel10/bootc-image-builder:10.1 \
  --type qcow2 \
  registry-${GUID}.${DOMAIN}/base 2>&1 >> /tmp/progress.log

cp -f qcow2/disk.qcow2 /var/lib/libvirt/images/bootc-vm.qcow2

# Tear down the initial VM (created at setup) before redeploying the hardened image
virsh destroy bootc-vm 2>/dev/null
virsh undefine bootc-vm 2>/dev/null

virt-install --name bootc-vm \
  --disk /var/lib/libvirt/images/bootc-vm.qcow2 \
  --import --memory 4096 --graphics none \
  --osinfo rhel10-unknown --noautoconsole --noreboot 2>&1 >> /tmp/progress.log

virsh start bootc-vm 2>&1 >> /tmp/progress.log

echo "Bootc VM deployed" >> /tmp/progress.log
