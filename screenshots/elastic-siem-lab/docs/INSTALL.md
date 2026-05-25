# Installation Guide — Elastic SIEM Lab

Full step-by-step build log for the Elastic Stack SIEM on Ubuntu in VMware Workstation.

---

## Prerequisites

- VMware Workstation (or VirtualBox)
- Ubuntu 22.04 LTS ISO
- Minimum VM specs: 4GB RAM, 2 vCPUs, 40GB disk
- Host machine with a browser (to access Kibana on port 5601)

---

## Step 1 — OS Hardening

```bash
# Full system update
sudo apt update && sudo apt upgrade -y

# Create a non-root admin user (if installed as root)
sudo adduser <yourname>
sudo usermod -aG sudo <yourname>

# Install baseline tools
sudo apt install -y curl wget git net-tools ufw openjdk-11-jdk

# Verify Java
java -version

# Enable firewall — allow SSH first so you don't lock yourself out
sudo ufw allow ssh
sudo ufw enable
sudo ufw status
```

> **Why UFW first?** UFW (Uncomplicated Firewall) is your first layer of defense. Always open SSH before enabling it so you don't get locked out of your own VM.

---

## Step 2 — Install & Configure Elasticsearch

Elasticsearch is the database. It stores and indexes all log events.

```bash
# Add Elastic's APT repo
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-7.x.list
sudo apt update

# Install
sudo apt install -y elasticsearch
```

Edit the config file:

```bash
sudo nano /etc/elasticsearch/elasticsearch.yml
```

Set this line (allows access from your host machine):

```yaml
network.host: 0.0.0.0
```

Start and enable:

```bash
sudo systemctl enable elasticsearch
sudo systemctl start elasticsearch

# Verify it's running
curl -X GET "localhost:9200/"
```

You should see a JSON response with cluster info.

---

## Step 3 — Install & Configure Logstash

Logstash is the pipeline. It receives raw logs from Filebeat, parses them, and forwards structured data to Elasticsearch.

```bash
sudo apt install -y logstash
```

Create the Beats input pipeline:

```bash
sudo nano /etc/logstash/conf.d/01-beats.conf
```

Paste the contents from [`../config/logstash-beats.conf`](../config/logstash-beats.conf).

Start and enable:

```bash
sudo systemctl enable logstash
sudo systemctl start logstash
sudo systemctl status logstash
```

---

## Step 4 — Install & Configure Kibana

Kibana is the analyst interface — your dashboard and log explorer.

```bash
sudo apt install -y kibana
sudo nano /etc/kibana/kibana.yml
```

Set these two lines:

```yaml
server.host: "0.0.0.0"
elasticsearch.hosts: ["http://localhost:9200"]
```

Start and open the firewall:

```bash
sudo systemctl enable kibana
sudo systemctl start kibana
sudo ufw allow 5601/tcp
```

From your host machine's browser, navigate to:

```
http://<ubuntu_vm_ip>:5601
```

You should see the Kibana welcome screen.

---

## Step 5 — Install & Configure Filebeat

Filebeat is the log shipper. It reads log files on the Ubuntu host and ships them to Logstash.

```bash
# Download and install Filebeat 7.x
wget https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-7.17.0-amd64.deb
sudo dpkg -i filebeat-7.17.0-amd64.deb

sudo nano /etc/filebeat/filebeat.yml
```

Paste the contents from [`../config/filebeat.yml`](../config/filebeat.yml).

Enable the system module (ships auth.log and syslog):

```bash
sudo filebeat modules enable system

# Test the config before starting
sudo filebeat test config

sudo systemctl enable filebeat
sudo systemctl start filebeat
sudo systemctl status filebeat
```

---

## Step 6 — Create Index Pattern in Kibana

1. Open Kibana at `http://<vm_ip>:5601`
2. Go to **Stack Management → Index Patterns**
3. Click **Create index pattern**
4. Enter `logs-*` as the pattern
5. Select `@timestamp` as the time field
6. Click **Create**

Now go to **Discover** — you should see log events flowing in.

---

## Verifying the Full Pipeline

Check all four services are running:

```bash
sudo systemctl status elasticsearch
sudo systemctl status logstash
sudo systemctl status kibana
sudo systemctl status filebeat
```

Test Elasticsearch is receiving data:

```bash
curl -X GET "localhost:9200/_cat/indices?v"
```

You should see `logs-YYYY.MM.dd` indices appearing.

---

## Troubleshooting

| Problem | Check |
|---|---|
| Kibana won't load | `sudo systemctl status kibana` — check for errors |
| No logs in Discover | Verify Filebeat is running; check index pattern matches |
| Elasticsearch not responding | Check RAM — ES needs at least 1GB heap |
| Port 5601 unreachable from host | `sudo ufw allow 5601/tcp` and check VM network is Bridged or NAT with port forward |

---

## Network Diagram

```
Host Machine (browser)
        │
        │ :5601 (HTTP)
        ▼
  Ubuntu VM (VMware)
  ┌────────────────────────────────┐
  │  Filebeat ──▶ Logstash :5044  │
  │                  │            │
  │                  ▼            │
  │           Elasticsearch :9200 │
  │                  │            │
  │                  ▼            │
  │            Kibana :5601       │
  └────────────────────────────────┘
```
