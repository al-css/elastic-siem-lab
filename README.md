# Elastic SIEM Home Lab

> A single-node Elastic Stack (ELK) SIEM built on an Ubuntu VM in VMware Workstation, with Filebeat shipping Linux system and auth logs for search and triage in Kibana. Built for my cybersecurity coursework in Intrusion Testing & Security Assessment and Communication & Network Security.

This is a learning lab, not a production deployment. The point was to stand the stack up end to end, turn on the security features, and understand how a log gets from `/var/log/auth.log` to a searchable event an analyst can triage.

---

## What it does

- **Collects** Ubuntu system and auth logs (`/var/log/syslog`, `/var/log/auth.log`) with the Filebeat `system` module
- **Parses** them with the module's ingest pipelines into structured ECS fields (`source.ip`, `user.name`, `system.auth.ssh.event`, …)
- **Stores and indexes** the events in Elasticsearch
- **Lets you search and triage** them in Kibana Discover — filter by user, source IP, or event type

The next step, writing an actual detection rule for this data, is worked through in [docs/detection-ssh-brute-force.md](docs/detection-ssh-brute-force.md).

---

## Architecture

```
Host machine (browser)
        │ :5601  (UFW: allowed from host IP only)
        ▼
┌───────────────────────────────────────────────┐
│ Ubuntu VM (VMware)                             │
│                                                │
│  Filebeat ──▶ Logstash ──▶ Elasticsearch       │
│  (agent)      :5044         :9200              │
│                             (security on)      │
│                                  ▲             │
│                                  │             │
│                             Kibana :5601       │
│                             (UI / triage)      │
└───────────────────────────────────────────────┘
```

**Log sources:** Ubuntu `syslog` and `auth.log`, via the Filebeat `system` module.

---

## Stack

All components are on the same version (install them together from the Elastic 7.x APT repo and they stay in sync).

| Component | Version | Role |
|---|---|---|
| Elasticsearch | 7.17.29 | Storage and search; security enabled |
| Logstash | 7.17.29 | Beats input → Elasticsearch, runs module ingest pipelines |
| Kibana | 7.17.29 | Search and triage UI (port 5601) |
| Filebeat | 7.17.29 | Log shipper (`system` module) |
| Ubuntu | 26.04 LTS | Host OS (VMware Workstation VM) |

Events land in the Filebeat module index, e.g. `filebeat-7.17.29-2026.05.25-000001`.

---

## Security hardening

The first build followed a lot of quick-start guides that leave the stack wide open. I went back and fixed that, because a SIEM full of auth logs is exactly the thing you don't want unauthenticated on your network:

- **Elasticsearch bound to `127.0.0.1`.** It was on `0.0.0.0`, which with a bridged VM exposed port 9200, with no login, to every device on the home network. Kibana and Logstash are on the same VM, so localhost is enough.
- **Authentication on** (`xpack.security.enabled: true`), with passwords set via `elasticsearch-setup-passwords`. Nothing reads or writes without credentials.
- **Least-privilege service accounts.** Logstash logs in as a `logstash_internal` user that can only write the `filebeat-*` indices, not as the `elastic` superuser. Kibana uses `kibana_system`.
- **No passwords in config files.** Credentials live in the Logstash and Kibana keystores and are referenced as `${ES_PWD}`.
- **Firewall.** UFW allows SSH and 5601 only from the host machine's IP; 9200 and 5044 are never exposed off the VM.

Full commands are in [docs/INSTALL.md](docs/INSTALL.md).

---

## Key configs

| File | Purpose |
|---|---|
| [config/elasticsearch.yml](config/elasticsearch.yml) | Localhost binding, single-node, security on |
| [config/kibana.yml](config/kibana.yml) | Host, ES connection, `kibana_system` login |
| [config/logstash-beats.conf](config/logstash-beats.conf) | Beats input → Elasticsearch, using module ingest pipelines |
| [config/filebeat.yml](config/filebeat.yml) | `system` module, Logstash output |

---

## Setup

Full step-by-step build with the security steps: [docs/INSTALL.md](docs/INSTALL.md).

Short version:
1. Prepare and harden the OS (updates, UFW)
2. Elasticsearch → configure → start → set built-in passwords
3. Kibana → keystore password → start → open 5601 to the host only
4. Logstash → least-privilege user → keystore → pipeline → start
5. Filebeat → enable `system` module → load ingest pipelines → start
6. Create the `filebeat-*` index pattern in Kibana → Discover

---

## Screenshots

See [screenshots/](screenshots/) for the stack running: services active, the Filebeat index with ~11.7k documents ingested, and parsed auth events in Discover.

---

## Skills demonstrated

- Linux server administration (Ubuntu, systemd, UFW)
- Elastic Stack deployment and configuration
- Log pipeline design (Beats → Logstash → Elasticsearch)
- Enabling and reasoning about stack security (auth, least privilege, keystores)
- Security log analysis (`auth.log`, `syslog`) and Kibana Discover / KQL

---

## Roadmap

- [ ] Run the SSH brute-force detection exercise ([guide](docs/detection-ssh-brute-force.md)) and record results
- [ ] Add a Windows VM as a second log source (Winlogbeat / Sysmon)
- [ ] Build a Kibana dashboard for authentication activity
- [ ] Add more threshold and correlation rules (sudo abuse, new-user creation)
- [ ] Explore Suricata for network-level events

---

## Course context

Built for **Intrusion Testing & Security Assessment** and **Communication & Network Security**, part of McGill's Certificate in Applied Cybersecurity, which emphasizes hands-on lab work.

---

## Author

**Ayman Al Labade** — Cybersecurity student
[LinkedIn](https://www.linkedin.com/in/ayman-al-labade) · [GitHub](https://github.com/al-css)
