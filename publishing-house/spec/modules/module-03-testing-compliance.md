# Module 03: Testing Compliance

### Brief Overview

This validation module runs entirely on the Bootc VM. The learner first confirms FAPolicyd application allow-listing is working by copying a known-good binary (`/bin/ls`) to the home directory and observing that it cannot be executed ("Operation not permitted"). They then run an OpenSCAP `xccdf` evaluation against the CIS Server Level 1 profile and grep the resulting score, expecting a value in the 90s. The module closes with a discussion of why rules pass, fail, or are not applicable, and recaps the core build-time security principles.

### Audience and Time

- **Personas:** Linux system administrators, platform engineers, and security/compliance engineers.
- **Prerequisites for this module:** Completion of Module 02 (the hardened image must be built and applied to the bootc VM).
- **Estimated duration:** 5 minutes.

### Learning Objectives

- Verify FAPolicyd blocks execution of binaries outside trusted paths.
- Verify compliance by running an OpenSCAP evaluation against the CIS Server Level 1 profile and checking the score.
- Analyze why individual rules pass, fail, or report as not applicable.

### Lab Structure

| Section | Title | Duration |
|---------|-------|----------|
| 1 | Testing FAPolicyd (Bootc VM) | 2 min |
| 2 | Testing SCAP compliance (Bootc VM) | 2 min |
| 3 | Understanding the results & principles | 1 min |

### Detailed Steps

1. On the **Bootc VM** tab, list the active FAPolicyd allow-list: `sudo fapolicyd-cli -l`.
2. Copy a known-good binary to the home directory: `cp /bin/ls ~`.
3. Attempt to run it: `~/ls`, and confirm it is denied with `Operation not permitted` (the binary is outside a trusted path on the read-only filesystem).
4. Run the OpenSCAP evaluation against the CIS Server Level 1 profile:
   `sudo oscap xccdf eval --profile xccdf_org.ssgproject.content_profile_cis_server_l1 --results ./results /usr/share/xml/scap/ssg/content/ssg-rhel10-ds.xml`.
5. Check the compliance score: `sudo grep score results`, expecting a value in the 90s (e.g. ~92.5).
6. Review the "Understanding the Results" discussion of why rules pass, fail, or are not applicable (system configuration, policy tailoring, runtime state) and the recap of core build-time security principles.

### Key Takeaways

- FAPolicyd prevents execution of binaries outside known trusted paths, even known-good ones relocated on the host.
- OpenSCAP can validate a deployed system against the same CIS profile that was applied at build time.
- A CIS Level 1 score in the 90s is a strong baseline; some rules legitimately fail or are not applicable due to tailoring, VM context, or runtime-only checks.
- Build-time security yields consistency, immutability, and efficiency across every deployed system.

### Infrastructure Notes

Runs entirely on the Bootc VM, which has a read-only (immutable) root filesystem. Requires the hardened image from Module 02 to have been applied. No build host or registry access needed in this module.
