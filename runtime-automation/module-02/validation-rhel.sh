#!/bin/sh
echo "Validating module-02" >> /tmp/progress.log

# Source environment variables if available
if [ -f /etc/profile.d/lab.sh ]; then
    . /etc/profile.d/lab.sh
fi

# Check that the hardened image was built and pushed to the registry
if ! skopeo inspect docker://registry-${GUID}.${DOMAIN}/base >/dev/null 2>&1; then
    echo "FAIL: Hardened image not found in registry"
    echo "HINT: Build and push the image with 'podman build --file Containerfile --tag registry-${GUID}.${DOMAIN}/base' then 'podman push registry-${GUID}.${DOMAIN}/base'"
    exit 1
fi

# Check that the image has the security profile label
if ! skopeo inspect --format '{{.Labels.profile}}' docker://registry-${GUID}.${DOMAIN}/base 2>/dev/null | grep -q "CIS Server Level 1"; then
    echo "FAIL: Image missing security profile label"
    echo "HINT: Ensure the Containerfile includes 'LABEL profile=\"CIS Server Level 1 base image\"' and rebuild the image"
    exit 1
fi

echo "PASS: module-02 objectives verified" >> /tmp/progress.log
exit 0
