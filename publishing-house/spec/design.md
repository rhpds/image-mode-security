# Image Mode Security and Compliance

## Overview

This hands-on lab shows how to bake security and compliance controls directly into a RHEL 10 Image Mode (bootc) image, so every system deployed from that image starts with a consistent, immutable security baseline. It exists because build-time hardening is more reliable and auditable than configuring hosts one at a time after deployment. Participants edit a Containerfile on a build host to install and enable FAPolicyd application allow-listing, tailor a CIS Server Level 1 SCAP policy with `autotailor`, apply it at build time with `oscap-im`, rebuild and push the hardened bootc image with Podman, then deploy it to a bootc VM with `bootc update --apply` and validate that FAPolicyd blocks unapproved binaries and that the OpenSCAP compliance score lands in the 90s.

## Target Audience

- **Role:** Linux system administrators, platform engineers, and security/compliance engineers working with RHEL.
- **Experience level:** Intermediate.
- **What they already know:** Comfort with the Linux command line, text editors (nano/vim), and basic container/image-build concepts; familiarity with RHEL Image Mode and bootc, plus security/compliance concepts (FAPolicyd, OpenSCAP, CIS benchmarks).
- **What they don't know:** How to embed FAPolicyd and a tailored CIS SCAP policy into a bootc image at build time, and how to validate those controls on the deployed system.

## Prerequisites

- Basic familiarity with RHEL Image Mode and bootc concepts.
- Understanding of security and compliance concepts (FAPolicyd, OpenSCAP, CIS benchmarks).
- Comfort with a terminal text editor (nano or vim).
- Recommended: complete an "Image Mode Fundamentals" lab first (this lab builds on those concepts).
- Automatic validation: No — prerequisites are advisory knowledge and are not machine-verifiable at lab start. The lab environment (build host + bootc build tooling) is provisioned by automation.

## Learning Objectives

1. Configure FAPolicyd application allow-listing in a bootc image.
2. Implement a tailored CIS Server Level 1 SCAP policy at build time.
3. Verify runtime security and compliance on the deployed bootc system.

## Content Type

Lab (hands-on).

## Products & Technologies

Red Hat products:

- Red Hat Enterprise Linux 10 (RHEL Image Mode)
- Red Hat Enterprise Linux security tooling: SCAP Security Guide (SSG) with the CIS Server Level 1 profile, OpenSCAP (openscap-utils, `oscap`, `oscap-im`, `autotailor`), FAPolicyd (`fapolicyd-cli`), the Linux audit subsystem, SELinux troubleshooting (setroubleshoot-server), and systemd/systemctl

Upstream projects and tools:

- bootc
- Podman
- Skopeo
- OpenSCAP
- FAPolicyd
- jq
- nano
- Containerfile format
- A lab-provisioned container registry

## Module Map

| Module | Title | Duration |
|--------|-------|----------|
| 1 | Lab Introduction | 3 min |
| 2 | Adding Security Controls | 10 min |
| 3 | Testing Compliance | 5 min |
| — | **Total hands-on** | **~15 min** |
| — | Intro / presentation | ~3 min |
| — | **Total lab** | **~18 min** |

## Difficulty Level

Intermediate.

## Environment

**Learner view:** At lab start the learner has two RHEL 10 systems reachable through separate SSH terminal tabs. The **Build host** (`/wetty/ssh/root`) is a RHEL 10 machine with a pre-configured bootc build environment, including a `~/bootc-base` directory containing an existing Containerfile. The **Bootc VM** (`/wetty_bootc_vm/ssh/root`) is a bootc-deployed guest that is created/updated during the lab from the hardened image the learner builds. Learners switch between the two tabs as directed by the module callouts. A lab-provisioned container registry endpoint (`registry-{guid}.{domain}`) is available for pushing and pulling the bootc image.

**Automation needed:** Yes.

Automation must provision the RHEL 10 build host with the bootc build toolchain (Podman, Skopeo, jq, and the pre-seeded `~/bootc-base` Containerfile), stand up (or make available) the container registry endpoint, and provide the bootc VM that is deployed/updated from the learner's hardened image during the lab. Automation approach is Ansible.

## Infrastructure Requirements

- **Cloud provider:** CNV (default)
- **Platform:** rhel-vms (not OpenShift)
- **Cluster type:** N/A (not OpenShift)
- **OCP version:** N/A
- **Topology:** Per-student (each learner needs their own build host + bootc VM)
- **Sizing:**
  - Build host — count 1, 4 vCPU, 8 GB RAM, 100 GB disk, RHEL 10. Disk sized for headroom for container image builds (Podman layers, pushed images, and a full RHEL image rebuild). *TBD — confirmed in infrastructure phase.*
  - Bootc VM — count 1, 2 vCPU, 4 GB RAM, 30 GB disk (read-only/immutable root filesystem), RHEL 10. *TBD — confirmed in infrastructure phase.*
- **Automation approach:** Ansible
- **AI/MaaS:** None
- **External services:** None external. A container registry is used for push/pull but appears lab-provisioned (`registry-{guid}.{domain}`), not a public dependency.
- **Non-GA products:** None (all products are GA)

## Assessment Strategy (Optional)

This is a Zero-Touch lab with solve/validate support. Completion is verifiable per module:

- **Module 1 (Lab Introduction):** No hands-on tasks; no verification (solveButton false).
- **Module 2 (Adding Security Controls):** Validate that the Containerfile installs and enables FAPolicyd plus the audit/SELinux/OpenSCAP tooling, that a tailored CIS Server Level 1 policy (`cis_server_l1_customized.xml`) exists and is referenced by an `oscap-im` build block, that the hardened image was built and pushed to the registry, and that the bootc VM was updated (`bootc update --apply`).
- **Module 3 (Testing Compliance):** Validate that FAPolicyd blocks execution of a binary copied to the home directory ("Operation not permitted") and that `oscap xccdf eval` against the CIS Server Level 1 profile produces a compliance score in the 90s.
