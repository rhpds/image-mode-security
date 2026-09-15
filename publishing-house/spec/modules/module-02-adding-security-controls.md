# Module 02: Adding Security Controls

### Brief Overview

This is the core hands-on module. On the build host the learner edits the existing `~/bootc-base/Containerfile` to install and enable FAPolicyd along with the audit subsystem, SELinux troubleshooting, and OpenSCAP tooling. They then tailor a CIS Server Level 1 SCAP policy with `autotailor` (re-enabling root login so the lab environment keeps working) and add an `oscap-im` build-time scan/remediation block with descriptive labels. Finally the learner rebuilds and pushes the hardened bootc image with Podman, inspects the applied labels with Skopeo and jq, then switches to the Bootc VM tab and applies the hardened image with `bootc update --apply`.

### Audience and Time

- **Personas:** Linux system administrators, platform engineers, and security/compliance engineers.
- **Prerequisites for this module:** Completion of Module 01; comfort editing files in nano and running container build commands.
- **Estimated duration:** 10 minutes.

### Learning Objectives

- Configure FAPolicyd application allow-listing by installing and enabling it in the Containerfile.
- Implement a tailored CIS Server Level 1 SCAP policy at build time using `autotailor` and `oscap-im`.
- Build and push the hardened bootc image and deploy it to the bootc VM.

### Lab Structure

| Section | Title | Duration |
|---------|-------|----------|
| 1 | Adding security controls: FAPolicyd (Build host) | 3 min |
| 2 | Tailoring SCAP for compliance (Build host) | 3 min |
| 3 | Building & pushing the bootc image (Build host) | 3 min |
| 4 | Applying the hardened image (Bootc VM) | 1 min |

### Detailed Steps

1. On the **Build host** tab, `cd ~/bootc-base` and open the Containerfile with `nano Containerfile`.
2. After the existing `systemctl mask` line, add a hardening block that installs the security tooling and enables FAPolicyd:
   `RUN dnf -y install audit fapolicyd openscap-utils scap-security-guide setroubleshoot-server` and `RUN systemctl enable fapolicyd`. Save and exit.
3. Tailor the CIS policy on the build host with `autotailor`, deselecting the root-login rule and writing a customized policy file:
   `autotailor --unselect xccdf_org.ssgproject.content_rule_sshd_disable_root_login --new-profile-id cis_server_l1_customized --output cis_server_l1_customized.xml /usr/share/xml/scap/ssg/content/ssg-rhel10-ds.xml cis_server_l1`.
4. Reopen the Containerfile and, after the `systemctl enable` line, add the SCAP block: a `LABEL profile=...`, `ENV profileID=cis_server_l1_customized`, `COPY $profileID.xml /tmp/$profileID.xml`, and `RUN oscap-im --profile $profileID --tailoring-file /tmp/$profileID.xml /usr/share/xml/scap/ssg/content/ssg-rhel10-ds.xml`.
5. Build the image: `podman build --file Containerfile --tag registry-{guid}.{domain}/base`, observing the per-rule pass/fail/notapplicable output as OpenSCAP remediates.
6. Push the image: `podman push registry-{guid}.{domain}/base`.
7. Inspect the applied labels: `skopeo inspect --format '{{json .Labels }}' docker://registry-{guid}.{domain}/base | jq`.
8. Switch to the **Bootc VM** tab and apply the hardened image: `sudo bootc update --apply`.

### Key Takeaways

- FAPolicyd needs only a `systemctl enable` in the Containerfile because systemd runs on full RHEL Image Mode hosts.
- Compliance policies usually require tailoring; `autotailor` produces a reusable tailoring file for a given base policy.
- `oscap-im` scans and remediates during the containerized build, and image labels record the applied compliance profile for humans and tooling.
- The hardened image is deployed to a running bootc host with a single `bootc update --apply`.

### Infrastructure Notes

Requires the build host's pre-seeded `~/bootc-base` Containerfile, the bootc build toolchain (Podman, Skopeo, jq), and the lab-provisioned registry endpoint `registry-{guid}.{domain}`. The build host needs disk headroom for image build layers and a full RHEL image rebuild. Learners must switch between the Build host and Bootc VM terminal tabs.
