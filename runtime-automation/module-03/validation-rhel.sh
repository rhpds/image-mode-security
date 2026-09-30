#!/bin/sh
echo "Validating module-03" >> /tmp/progress.log

# Find SSH key (GUID may not be set in non-login shell)
KEY=$(ls /root/.ssh/*key 2>/dev/null | head -1)
if [ -z "$KEY" ]; then
    echo "FAIL: SSH key not found"
    echo "HINT: Contact lab support - SSH key should exist at /root/.ssh/"
    exit 1
fi

# Check that fapolicyd service is active on the bootc-vm
if ! ssh -i "$KEY" -o StrictHostKeyChecking=no -o ConnectTimeout=10 core@bootc-vm 'systemctl is-active --quiet fapolicyd' 2>/dev/null; then
    echo "FAIL: fapolicyd service not active on bootc-vm"
    echo "HINT: The security-hardened image should have fapolicyd enabled and running. Check that the bootc update completed successfully."
    exit 1
fi

# Check that SCAP evaluation results file exists
if ! ssh -i "$KEY" -o StrictHostKeyChecking=no -o ConnectTimeout=10 core@bootc-vm 'test -f /home/core/results' 2>/dev/null; then
    echo "FAIL: SCAP results file not found"
    echo "HINT: Run the SCAP evaluation with 'sudo oscap xccdf eval --profile xccdf_org.ssgproject.content_profile_cis_server_l1 --results ./results /usr/share/xml/scap/ssg/content/ssg-rhel10-ds.xml'"
    exit 1
fi

echo "PASS: module-03 objectives verified" >> /tmp/progress.log
exit 0
