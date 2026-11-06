# Detection Exercise — SSH Brute Force (MITRE ATT&CK T1110.001)

The goal of this exercise is the **detection** side: produce some failed-SSH traffic between your own lab VMs, then find it in Kibana and turn the search into a detection rule. The focus below is the analyst workflow, not the attack.

**Status:** guide written, exercise not run yet. Fill in [Results](#results) after running it.

> **Only generate traffic against machines you own.** Keep this to your own lab VMs. Testing against any other system without written permission is illegal.

---

## The technique

| | |
|---|---|
| Tactic | Credential Access (TA0006) |
| Technique | Brute Force (T1110) |
| Sub-technique | Password Guessing (T1110.001) |
| Data source | Linux `/var/log/auth.log` via the Filebeat `system` module |
| What it looks like | Repeated `Failed password` / `Invalid user` events from one source IP in a short window |

---

## Prerequisites

- The stack from [INSTALL.md](INSTALL.md) is running, with ingest pipelines loaded (Step 5a). Confirm in Discover that `event.dataset : "system.auth"` events include the `system.auth.ssh.event` and `source.ip` fields.
- A second lab VM that can reach the Ubuntu VM on port 22.
- A throwaway test account on the Ubuntu VM, so you never exercise this against your real admin login:

```bash
sudo adduser labtest
```

---

## 1 — Generate some failed logins

You just need a batch of failed SSH attempts in `auth.log` from another host. The simplest way is to try to SSH in as `labtest` a number of times with the wrong password:

```bash
# from the other VM, repeat a handful of times (each prompts for a password — type a wrong one)
ssh labtest@<ubuntu-vm-ip>
```

If you later want to study higher-volume patterns, Kali includes auditing tools such as Hydra for exactly this kind of **authorized** lab testing; see the tool's own `-h` help and man page for usage. Keep the volume low (a few parallel connections at most) so you don't just trip the SSH server's own rate limiting. Also try connecting once as a username that does not exist, so you can compare `Failed` (real account, wrong password) against `Invalid` (no such user) in the logs.

---

## 2 — Find it in Kibana (Discover)

Index pattern `filebeat-*`, time range "Last 15 minutes":

```
event.dataset : "system.auth" and system.auth.ssh.event : ("Failed" or "Invalid")
```

Add the columns `source.ip`, `user.name` and `system.auth.ssh.event`. You should see the burst of failures from the other VM's IP.

**Analyst questions to answer:**

1. Which IP generated the failures, and how many were there?
2. Which accounts were targeted? Did they exist (`Failed`) or not (`Invalid`)?
3. **Most important:** did any attempt succeed? Check for a successful login from the same IP:

```
system.auth.ssh.event : "Accepted" and source.ip : "<attacker-ip>"
```

A run of failures followed by `Accepted` from the same IP points to a likely compromised account, a much higher-severity finding than failures alone.

Save the search as **SSH brute force - failed logins**.

---

## 3 — Visualize it

**Visualize Library → Create → Lens**, index `filebeat-*`, same query as above:

- Horizontal axis: `@timestamp` (date histogram)
- Vertical axis: Count
- Break down by: top 5 values of `source.ip`

A normal host has a few failures a day; the generated traffic shows up as a tall spike from one IP. Add it to a dashboard named **SSH Activity**.

---

## 4 — Build the detection rule

### Extra prerequisites for rules

Kibana's alerting framework (which runs detection rules) needs two more things on a self-managed stack:

1. **TLS between Kibana and Elasticsearch** (rules run with API keys, which need HTTPS). Follow Elastic's guide: [Set up basic security plus HTTPS (7.17)](https://www.elastic.co/guide/en/elasticsearch/reference/7.17/security-basic-setup-https.html).
2. **An encryption key** for saved objects, stored in the keystore:

```bash
sudo /usr/share/kibana/bin/kibana-encryption-keys generate
sudo /usr/share/kibana/bin/kibana-keystore add xpack.encryptedSavedObjects.encryptionKey
sudo systemctl restart kibana
```

See [Alerting setup (Kibana 7.17)](https://www.elastic.co/guide/en/kibana/7.17/alerting-setup.html). Until both are done, steps 2 and 3 above are your "manual" detection.

### Rule settings

**Security → Detections → Manage rules → Create new rule → Threshold**

| Setting | Value |
|---|---|
| Index patterns | `filebeat-*` |
| Custom query | `event.dataset : "system.auth" and system.auth.ssh.event : ("Failed" or "Invalid")` |
| Group by | `source.ip` |
| Threshold | `>= 10` |
| Name | SSH brute force from a single source |
| Severity / risk score | Medium / 47 |
| MITRE ATT&CK | Credential Access → Brute Force → Password Guessing (T1110.001) |
| Runs every | 5 minutes, with 1 minute additional look-back |

**Tuning:** 10 failures in 5 minutes from one IP is a starting point, not a final number. If a forgetful user or a misconfigured script trips it, raise the threshold or add an exception for that IP. Keeping it too low creates noise; too high misses slow attempts. Write down why you picked the number.

---

## What this demonstrates

- Reading parsed auth events, not raw log lines
- The difference between `Failed` (real user) and `Invalid` (no such user)
- Checking whether an attack **succeeded**, not just that it happened
- Turning an ad-hoc search into a repeatable threshold rule mapped to ATT&CK
- Thinking about false positives before deploying a rule

---

## Results

_To be filled in after running the exercise:_

- Source IP observed and number of failed attempts:
- Accounts targeted (existing vs invalid):
- Did any attempt succeed?
- Screenshot of the Discover results:
- Screenshot of the rule firing:
- Threshold chosen and why:
