# Elastic SIEM Lab — Home SOC Environment

> A fully functional Security Information and Event Management (SIEM) lab built on the Elastic Stack (ELK), deployed inside a VMware Workstation Ubuntu VM. Built as part of my cybersecurity studies in Intrusion Testing & Security Assessment.

---

## Project Overview

This lab simulates a real SOC analyst environment. It ingests system logs, parses them through a pipeline, and surfaces security-relevant events in a Kibana dashboard — the same toolchain used in enterprise SOCs.

### Architecture

```
┌─────────────────────────────────────────────────────┐
│                  Ubuntu VM (VMware)                  │
│                                                     │
│  ┌──────────┐    ┌──────────┐    ┌───────────────┐  │
│  │ Filebeat │───▶│ Logstash │───▶│ Elasticsearch │  │
│  │ (agent)  │    │(pipeline)│    │  (data store) │  │
│  └──────────┘    └──────────┘    └───────┬───────┘  │
│                                          │           │
│                                   ┌──────▼──────┐   │
│                                   │   Kibana    │   │
│                                   │  (UI :5601) │   │
│                                   └─────────────┘   │
└─────────────────────────────────────────────────────┘
```

**Log Sources:** Ubuntu system logs (`/var/log/syslog`, `/var/log/auth.log`) via Filebeat system module

---

## Stack

| Component | Version | Role |
|---|---|---|
| Elasticsearch | 7.x | Data storage and search engine |
| Logstash | 7.x | Log parsing and pipeline |
| Kibana | 7.x | Analyst dashboard (port 5601) |
| Filebeat | 7.x | Log shipper / agent |
| Ubuntu | 22.04 LTS | Host OS (VMware Workstation VM) |

---

## What It Does

- **Ingests** system and auth logs from the Ubuntu VM in real time
- **Parses** raw log data through a Logstash pipeline into structured JSON
- **Indexes** events into Elasticsearch with daily rolling indices (`logs-YYYY.MM.dd`)
- **Visualizes** events in Kibana Discover — queryable, filterable, searchable
- **Detects** authentication events, sudo usage, SSH logins via Filebeat system module

---

## Setup

See [`docs/INSTALL.md`](docs/INSTALL.md) for the full step-by-step build guide.

**Quick summary:**
1. OS hardening (updates, UFW firewall, SSH)
2. Install Elasticsearch → configure → start
3. Install Logstash → configure Beats input pipeline → start
4. Install Kibana → configure → start
5. Install Filebeat → enable system module → point to Logstash → start
6. Create index pattern in Kibana → explore logs

---

## Key Configs

| File | Purpose |
|---|---|
| [`config/logstash-beats.conf`](config/logstash-beats.conf) | Logstash pipeline: Beats input → Elasticsearch output |
| [`config/filebeat.yml`](config/filebeat.yml) | Filebeat config: system module, Logstash output |
| [`config/elasticsearch.yml`](config/elasticsearch.yml) | Elasticsearch network binding |
| [`config/kibana.yml`](config/kibana.yml) | Kibana host and ES connection |

---

## Skills Demonstrated

- Linux server administration (Ubuntu, systemd, UFW)
- ELK Stack deployment and configuration
- Log pipeline design (Beats → Logstash → Elasticsearch)
- Security log analysis (auth.log, syslog)
- Network service management and firewall rules
- SOC analyst tooling (Kibana Discover, index patterns)

---

## Course Context

Built for **Intrusion Testing & Security Assessment** and **Communication & Network Security** — part of a cybersecurity program focused on practical, hands-on lab environments.

---

## Next Steps / Roadmap

- [ ] Add Windows VM as a second log source (Sysmon + Elastic Agent)
- [ ] Build Kibana dashboards for failed SSH login detection
- [ ] Add Suricata IDS for network-level alerting
- [ ] Deploy Wazuh on top of ELK for HIDS capability
- [ ] Create detection rules for brute-force patterns

---

## Author

**Ayman Al Labade**  
Cybersecurity Student  
[LinkedIn](www.linkedin.com/in/ayman-al-labade) | [GitHub](https://github.com/al-css)
