# Installation Guide — Elastic SIEM Lab

Step-by-step build of a single-node Elastic Stack 7.17 SIEM on Ubuntu in VMware Workstation, with security turned on.

> **Lab only.** This is a learning setup on one VM. Run it on a host-only or NAT network if you can. If the VM is bridged, it sits on your home network next to every other device, so the firewall and passwords in this guide matter.

---

## Prerequisites

- VMware Workstation (or VirtualBox)
- Ubuntu LTS ISO (tested on Ubuntu 26.04 LTS; 22.04 and 24.04 work the same way)
- VM specs: 2 vCPUs, 40 GB disk, **at least 4 GB RAM, 8 GB recommended** (Elasticsearch alone used about 2.9 GB in this lab)
- Host machine with a browser (for Kibana on port 5601)

All four Elastic components must be the **same version**. Installing them all from the Elastic APT repository (Step 2) takes care of that; this lab ended up on 7.17.29.

---

## Step 1 — Prepare and harden the OS

```bash
# Full system update
sudo apt update && sudo apt upgrade -y

# Create a non-root admin user (if you installed as root)
sudo adduser <yourname>
sudo usermod -aG sudo <yourname>

# Baseline tools
sudo apt install -y curl wget gpg apt-transport-https ufw

# Firewall: allow SSH first so you don't lock yourself out
sudo ufw allow ssh            # tighter: sudo ufw allow from <host-ip> to any port 22 proto tcp
sudo ufw enable
sudo ufw status verbose
```

> **Why UFW first?** UFW (Uncomplicated Firewall) blocks every incoming connection you have not allowed. Open SSH before enabling it so you can still get back in.
>
> **Java:** Elasticsearch and Logstash 7.17 ship with their own Java runtime, so you don't need to install OpenJDK.

---

## Step 2 — Install Elasticsearch

Elasticsearch is the database. It stores and indexes every log event.

```bash
# Add Elastic's signing key and the 7.x APT repository
# (apt-key is deprecated on current Ubuntu, so the key goes in its own keyring)
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-7.x.list
sudo apt update

sudo apt install -y elasticsearch
```

Edit the config:

```bash
sudo nano /etc/elasticsearch/elasticsearch.yml
```

Use the settings from [`../config/elasticsearch.yml`](../config/elasticsearch.yml):

```yaml
cluster.name: siem-lab
node.name: siem-node-1
network.host: 127.0.0.1       # localhost only: Kibana and Logstash are on this VM
discovery.type: single-node
xpack.security.enabled: true
```

Start it:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now elasticsearch
sudo systemctl status elasticsearch
```

### Step 2b — Set the built-in passwords

With security on, nothing works until the built-in users have passwords:

```bash
sudo /usr/share/elasticsearch/bin/elasticsearch-setup-passwords auto
```

This prints random passwords for `elastic`, `kibana_system`, `logstash_system` and others. **Save them in a password manager now**; they are only shown once. `elastic` is the superuser. Use it for admin work only.

Check it worked (curl asks for the password):

```bash
curl -u elastic http://localhost:9200/
```

You should see JSON with the cluster name and `"number" : "7.17.x"`. Without `-u elastic` you should now get a `401` error, which proves authentication is on.

---

## Step 3 — Install Kibana

Kibana is the analyst interface: search, dashboards and detection rules.

```bash
sudo apt install -y kibana
sudo nano /etc/kibana/kibana.yml
```

Use the settings from [`../config/kibana.yml`](../config/kibana.yml):

```yaml
server.host: "0.0.0.0"
server.name: "siem-lab-kibana"
elasticsearch.hosts: ["http://localhost:9200"]
elasticsearch.username: "kibana_system"
```

Store the `kibana_system` password in the Kibana keystore instead of the config file:

```bash
sudo /usr/share/kibana/bin/kibana-keystore add elasticsearch.password
# paste the kibana_system password from Step 2b
```

Start Kibana and open port 5601 **only to your host machine**:

```bash
sudo systemctl enable --now kibana

# Find your host machine's IP (on Windows: ipconfig), then:
sudo ufw allow from <host-ip> to any port 5601 proto tcp
```

Browse to `http://<vm-ip>:5601` from the host and log in as `elastic`.

> **Even safer:** set `server.host: "localhost"`, don't open 5601 at all, and reach Kibana through an SSH tunnel: `ssh -L 5601:localhost:5601 <user>@<vm-ip>`, then browse `http://localhost:5601`. The login then travels inside SSH instead of plain HTTP.

---

## Step 4 — Install Logstash

Logstash is the pipeline. It receives events from Filebeat and forwards them to Elasticsearch.

```bash
sudo apt install -y logstash
```

### 4a — Create a Logstash user with only the rights it needs

Logstash should not log in as `elastic`. Create a role that can only write to the Filebeat indices, and a user with that role (each command asks for the `elastic` password):

```bash
curl -u elastic -X POST "http://localhost:9200/_security/role/logstash_writer" \
  -H 'Content-Type: application/json' -d '{
  "cluster": ["manage_index_templates", "monitor", "manage_ilm"],
  "indices": [{
    "names": ["filebeat-*"],
    "privileges": ["write", "create", "create_index", "manage", "manage_ilm"]
  }]
}'

curl -u elastic -X POST "http://localhost:9200/_security/user/logstash_internal" \
  -H 'Content-Type: application/json' -d '{
  "password": "<choose-a-long-password>",
  "roles": ["logstash_writer"],
  "full_name": "Internal Logstash user"
}'
```

This is the principle of least privilege: if the Logstash config ever leaks, the account can't read or delete anything else.

### 4b — Keep that password out of the config file

```bash
sudo /usr/share/logstash/bin/logstash-keystore --path.settings /etc/logstash create
sudo /usr/share/logstash/bin/logstash-keystore --path.settings /etc/logstash add ES_PWD
# paste the logstash_internal password
```

The pipeline refers to it as `${ES_PWD}`. If Logstash later logs a permission error about the keystore, give the service user access: `sudo chown logstash:logstash /etc/logstash/logstash.keystore`.

### 4c — Add the pipeline and start

```bash
sudo nano /etc/logstash/conf.d/01-beats.conf
# paste the contents of ../config/logstash-beats.conf

# Test the config syntax before starting
sudo -u logstash /usr/share/logstash/bin/logstash --path.settings /etc/logstash -t

sudo systemctl enable --now logstash
sudo systemctl status logstash
```

The Beats input listens on `127.0.0.1:5044`, so no firewall rule is needed while Filebeat runs on the same VM.

---

## Step 5 — Install Filebeat

Filebeat is the log shipper. It reads log files on the VM and sends them to Logstash.

```bash
sudo apt install -y filebeat      # same version as the rest of the stack
sudo nano /etc/filebeat/filebeat.yml
# paste the contents of ../config/filebeat.yml

# Enable the system module (syslog + auth.log)
sudo filebeat modules enable system
sudo filebeat test config
```

### 5a — Load the ingest pipelines and index template (one time)

Filebeat's modules parse logs with **ingest pipelines** that run inside Elasticsearch. Filebeat can only load them when it talks to Elasticsearch directly, so point it there just for this command. `read -s` asks for the password without echoing it or saving it in your shell history:

```bash
read -s -p "elastic password: " ES_PWD; echo
sudo filebeat setup --pipelines --modules system --index-management \
  -E output.logstash.enabled=false \
  -E 'output.elasticsearch.hosts=["localhost:9200"]' \
  -E output.elasticsearch.username=elastic \
  -E output.elasticsearch.password="$ES_PWD"
unset ES_PWD
```

Skip this and auth events arrive as one unparsed `message` field: no `source.ip`, no `system.auth.ssh.event`, and nothing for a detection rule to match on.

### 5b — Start

```bash
sudo filebeat test output        # should connect to localhost:5044
sudo systemctl enable --now filebeat
sudo systemctl status filebeat
```

---

## Step 6 — Create the index pattern in Kibana

1. Open Kibana and log in as `elastic`
2. Go to **Stack Management → Index Patterns → Create index pattern**
3. Enter `filebeat-*`
4. Select `@timestamp` as the time field and click **Create**

Go to **Discover**, pick `filebeat-*`, and events should be flowing in.

---

## Verifying the full pipeline

```bash
# All four services running?
systemctl is-active elasticsearch logstash kibana filebeat

# Events landing in the Filebeat index? (asks for the elastic password)
curl -u elastic "http://localhost:9200/_cat/indices/filebeat-*?v"
```

You should see an index such as `filebeat-7.17.29-2026.05.25-000001` with a growing `docs.count`.

**Check the parsing worked.** In Discover, search:

```
event.dataset : "system.auth"
```

Open an event. You should see parsed fields such as `system.auth.ssh.event`, `system.auth.sudo.command`, `user.name` and (for SSH) `source.ip`. If you only see `message`, the ingest pipelines are missing: re-run Step 5a and restart Logstash.

**Check the hardening worked.** From the host machine:

```bash
curl http://<vm-ip>:9200/      # should fail to connect (Elasticsearch is localhost-only)
nmap -p 22,5044,5601,9200 <vm-ip>   # from Kali: only 22 and 5601 should be open
```

---

## Troubleshooting

| Problem | Check |
|---|---|
| Elasticsearch won't start | `sudo journalctl -u elasticsearch -n 50`; usually low RAM or a YAML indentation error |
| `401 Unauthorized` from curl | Expected without `-u elastic`; with it, re-check the password from Step 2b |
| Kibana says "Kibana server is not ready yet" | Wrong `kibana_system` password in the keystore; re-run the `kibana-keystore add` command and restart Kibana |
| Logstash: `pipeline with id [filebeat-7.17.x-system-auth-pipeline] does not exist` | The ingest pipelines were never loaded; run Step 5a |
| No logs in Discover | Filebeat running? Index pattern is `filebeat-*`? Time range wide enough? |
| Only a `message` field, no parsed fields | Logstash output is missing `pipeline => "%{[@metadata][pipeline]}"`, or Step 5a was skipped |
| Port 5601 unreachable from host | `sudo ufw status`: is the `allow from <host-ip>` rule there? Is the VM on bridged or NAT with a port forward? |

---

## Network diagram

```
Host machine (browser)
        │
        │ :5601  (UFW: allowed from host IP only)
        ▼
 Ubuntu VM (VMware)
 ┌─────────────────────────────────────────┐
 │ Filebeat ──▶ Logstash 127.0.0.1:5044    │
 │                   │                     │
 │                   ▼                     │
 │      Elasticsearch 127.0.0.1:9200       │
 │      (security on, ingest pipelines)    │
 │                   ▲                     │
 │                   │                     │
 │          Kibana 0.0.0.0:5601            │
 └─────────────────────────────────────────┘
```

---

## Official references

- [Install Elasticsearch with Debian package (7.17)](https://www.elastic.co/guide/en/elasticsearch/reference/7.17/deb.html)
- [Set up minimal security for Elasticsearch (7.17)](https://www.elastic.co/guide/en/elasticsearch/reference/7.17/security-minimal-setup.html)
- [Logstash: use ingest pipelines for parsing](https://www.elastic.co/guide/en/logstash/7.17/use-ingest-pipelines.html)
- [Logstash secrets keystore (7.17)](https://www.elastic.co/guide/en/logstash/7.17/keystore.html)
