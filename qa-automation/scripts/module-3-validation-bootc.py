#!/usr/bin/env python3
"""Validate the documented module-3 exercises on the Bootc guest, as root."""

import json
import math
import os
from pathlib import Path
import pwd
import shutil
import subprocess
import tempfile
import xml.etree.ElementTree as ET

PROFILE = "xccdf_org.ssgproject.content_profile_cis_server_l1"
DATASTREAM = "/usr/share/xml/scap/ssg/content/ssg-rhel10-ds.xml"
NS = {"x": "http://checklists.nist.gov/xccdf/1.2"}


def compliance_score(path):
    root = ET.parse(path).getroot()
    results = root.findall(".//x:TestResult", NS)
    if root.tag == "{" + NS["x"] + "}TestResult":
        results.insert(0, root)
    if len(results) != 1:
        raise ValueError("Expected exactly one completed XCCDF TestResult")
    result = results[0]
    profile = result.find("x:profile", NS)
    if profile is None or profile.get("idref") != PROFILE:
        raise ValueError("Scan did not evaluate the documented CIS Server L1 profile")
    rules = result.findall("x:rule-result/x:result", NS)
    if not rules or any(rule.text in ("error", "unknown") for rule in rules):
        raise ValueError("Scan lacks rule results or contains evaluation errors")
    scores = result.findall("x:score[@system='urn:xccdf:scoring:default']", NS)
    if len(scores) != 1 or float(scores[0].get("maximum", "0")) != 100:
        raise ValueError("Expected one default score with maximum 100")
    score = float(scores[0].text or "nan")
    if not math.isfinite(score) or not 90 <= score <= 100:
        raise ValueError("CIS score does not meet the guide's 90-or-higher expectation")
    return score


def verify_denial(returncode, output):
    # A missing command, permission-bit failure, or successful execution is not
    # evidence of the documented policy denial. LC_ALL=C makes this stable.
    if returncode == 0 or "Operation not permitted" not in output:
        raise ValueError("Copied executable did not produce the expected policy denial")


def run(argv, timeout=60):
    return subprocess.run(argv, capture_output=True, text=True, timeout=timeout,
                          env={**os.environ, "LC_ALL": "C"})


def main():
    if os.geteuid() != 0:
        raise ValueError("Run this validator as root on the Bootc guest")
    # Do not mistake the build host's labels/packages for the deployed system.
    if not Path("/run/ostree-booted").exists():
        raise ValueError("Target is not an OSTree/Bootc booted guest")
    if run(["systemctl", "is-active", "--quiet", "fapolicyd"]).returncode:
        raise ValueError("FAPolicyd is not active on the Bootc guest")
    account = pwd.getpwnam("core")
    directory = Path(tempfile.mkdtemp(prefix="qa-compliance-", dir="/var/tmp"))
    rules = run(["fapolicyd-cli", "-l"])
    (directory / "fapolicyd-rules.log").write_text(rules.stdout + rules.stderr)
    if rules.returncode:
        raise ValueError("FAPolicyd policy listing failed")
    probe_dir = Path(tempfile.mkdtemp(prefix="qa-denial-", dir=account.pw_dir))
    try:
        os.chown(probe_dir, account.pw_uid, account.pw_gid)
        probe = probe_dir / "ls"
        shutil.copyfile("/bin/ls", probe)
        os.chmod(probe, 0o755)
        os.chown(probe, account.pw_uid, account.pw_gid)
        result = run(["runuser", "-u", "core", "--", str(probe)])
        output = result.stdout + result.stderr
        (directory / "execution-denial.log").write_text(output)
        verify_denial(result.returncode, output)
    finally:
        # Remove only this validator's temporary executable, never lab resources.
        shutil.rmtree(probe_dir)
    scan = run(["oscap", "xccdf", "eval", "--profile", PROFILE,
                "--results", str(directory / "results.xml"), DATASTREAM], timeout=1800)
    (directory / "oscap.log").write_text(scan.stdout + scan.stderr)
    # OpenSCAP returns 2 for a completed evaluation with failing rules.
    if scan.returncode not in (0, 2):
        raise ValueError("OpenSCAP evaluation failed; findings exit code 2 is allowed")
    score = compliance_score(directory / "results.xml")
    print(json.dumps({"status": "pass", "module": "module-03-testing-compliance",
                      "fapolicyd_denial": True, "cis_score": score,
                      "evidence_directory": str(directory)}))


if __name__ == "__main__":
    try:
        main()
    except (ValueError, OSError, KeyError, subprocess.SubprocessError, ET.ParseError) as error:
        print(json.dumps({"status": "fail", "module": "module-03-testing-compliance",
                          "error": str(error)}))
        raise SystemExit(1)
