# Module 01: Lab Introduction

### Brief Overview

This introductory module sets expectations for the lab and explains why building security and compliance controls into images at build time is advantageous. It introduces the three things the learner will do — add FAPolicyd application allow-listing, apply a tailored CIS Server Level 1 SCAP policy at build time, and validate compliance on the deployed system — and describes the two-machine lab environment (a RHEL 10 build host and a bootc VM deployed during the lab). There are no hands-on tasks in this module; the solve button is disabled.

### Audience and Time

- **Personas:** Linux system administrators, platform engineers, and security/compliance engineers.
- **Prerequisites for this module:** None beyond the lab-level prerequisites (basic familiarity with RHEL Image Mode/bootc, security/compliance concepts, and a terminal text editor). Completing an "Image Mode Fundamentals" lab first is recommended.
- **Estimated duration:** 3 minutes (narrative only, no hands-on).

### Learning Objectives

- Explore the goals of the lab: build-time FAPolicyd allow-listing, a tailored CIS Server Level 1 SCAP policy, and compliance validation.
- Analyze why build-time security offers consistency, immutability, auditability, and efficiency.

### Lab Structure

| Section | Title | Duration |
|---------|-------|----------|
| 1 | What You'll Learn | 1 min |
| 2 | Why Security at Build Time? | 1 min |
| 3 | Lab Environment & Prerequisites | 1 min |

### Detailed Steps

1. Read the welcome and the "What You'll Learn" overview: add security controls (FAPolicyd), apply SCAP policies (OpenSCAP/CIS), and test compliance.
2. Review the "Why Security at Build Time?" benefits: consistency, immutability, auditability, and efficiency.
3. Review the "Lab Environment" description: a RHEL 10 Build Host with a pre-configured bootc build environment, and a Bootc VM that will be deployed during the lab from the hardened image.
4. Review the prerequisites and the note recommending the "Image Mode Fundamentals" lab.
5. Proceed to the next module to begin adding security controls.

### Key Takeaways

- The lab's goal is to embed security and compliance into a bootc image rather than configuring hosts individually.
- Build-time security delivers consistency, immutability, auditability, and efficiency.
- The environment has two machines: a build host and a bootc VM deployed during the lab.

### Infrastructure Notes

No hands-on tasks; `solveButton` is false for this module. No validation script required.
