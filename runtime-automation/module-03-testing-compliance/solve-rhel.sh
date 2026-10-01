#!/bin/sh
echo "Running compliance tests..." >> /tmp/progress.log

# Find SSH key
KEY=$(ls /root/.ssh/*key 2>/dev/null | head -1)

if [ -z "$KEY" ]; then
    echo "FAIL: SSH key not found" >> /tmp/progress.log
    exit 1
fi

# Wait for VM to be fully ready after reboot from module-02
sleep 20

# Run SCAP evaluation on the bootc-vm
ssh -i "$KEY" -o StrictHostKeyChecking=no -o ConnectTimeout=30 core@bootc-vm \
  'sudo oscap xccdf eval --profile xccdf_org.ssgproject.content_profile_cis_server_l1 --results ./results /usr/share/xml/scap/ssg/content/ssg-rhel10-ds.xml' 2>&1 >> /tmp/progress.log || true

echo "Compliance tests complete" >> /tmp/progress.log
