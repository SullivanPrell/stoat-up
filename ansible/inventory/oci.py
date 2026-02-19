#!/usr/bin/env python

import json
import subprocess
import sys

def get_terraform_output():
    try:
        output = subprocess.check_output(
            ["terraform", "output", "-json"],
            cwd="../../terraform"
        ).decode("utf-8")
        return json.loads(output)
    except (subprocess.CalledProcessError, FileNotFoundError, json.JSONDecodeError) as e:
        print(f"Error getting Terraform output: {e}", file=sys.stderr)
        return None

def main():
    output = get_terraform_output()
    if not output or "instance_public_ip" not in output:
        inventory = {"_meta": {"hostvars": {}}}
        print(json.dumps(inventory))
        return

    public_ip = output["instance_public_ip"]["value"]
    inventory = {
        "oci": {
            "hosts": [public_ip],
        },
        "_meta": {
            "hostvars": {
                public_ip: {
                    "ansible_user": "ubuntu",
                }
            }
        }
    }
    print(json.dumps(inventory, indent=4))

if __name__ == "__main__":
    main()
