# Phase 1 — Stack Verification

## Environment

| Item | Value |
|------|-------|
| Host OS | Ubuntu 26.04 LTS (Resolute) |
| Hypervisor | VMware Workstation |
| Elasticsearch | 7.17.29 |
| Logstash | 7.17.x |
| Kibana | 7.17.29 |
| Filebeat | 7.17.29 |

## Objective

Verify all four ELK stack components are running and ingesting logs
before adding the Detection Rule Pack.

---

## Verification Steps

### 1. Check all services

```bash
sudo systemctl status elasticsearch kibana logstash filebeat --no-pager
```

Expected: all four show `active (running)`.

📸 Screenshot: `screenshots/phase-1/01-stack-running.png`

---

### 2. Confirm Elasticsearch responds

```bash
curl -s http://localhost:9200
```

Expected output:

```json
{
  "name" : "HUB-UBUNTU",
  "cluster_name" : "elasticsearch",
  "version" : {
    "number" : "7.17.29"
  },
  "tagline" : "You Know, for Search"
}
```

---

### 3. Check existing indices

```bash
curl -s http://localhost:9200/_cat/indices?v
```

At time of verification, the following indices existed:

| Index | Docs | Status |
|-------|------|--------|
| filebeat-7.17.29-2026.05.25-000001 | 15,163 | yellow |
| .kibana_7.17.29_001 | 2,483 | green |
| .geoip_databases | 43 | green |

> **Note:** The filebeat index shows yellow because Elasticsearch expects
> a replica shard on a second node. In a single-node lab this is normal
> and harmless — all data is intact.

📸 Screenshot: `screenshots/phase-1/02-existing-indices.png`

---

### 4. Access Kibana

Kibana is accessed from the Windows host browser at: http://192.168.2.22:5601

> To verify Kibana is bound to the port from the Ubuntu terminal:
> ```bash
> sudo ss -tlnp | grep 5601
> ```
> Expected: `node` listening on `0.0.0.0:5601`

📸 Screenshot: `screenshots/phase-1/03-kibana-home.png`

---

### 5. Verify data is visible in Kibana Discover

1. Open `http://192.168.2.22:5601` in browser
2. Menu (top left) → **Discover**
3. Confirm index pattern is `filebeat-*`
4. Set time range to **Last 7 days** (top right)
5. Confirm log events are visible in the histogram and list

📸 Screenshot: `screenshots/phase-1/04-kibana-discover-existing-data.png`

---

## Result

All four components confirmed healthy:

| Component | Status | Port |
|-----------|--------|------|
| Elasticsearch | active (running) | 9200 |
| Kibana | active (running) | 5601 |
| Logstash | active (running) | 5044 |
| Filebeat | active (running) | — |

15,163 events already indexed. Stack is ready for Phase 2 — Logstash
pipeline upgrade and Detection Rule Pack build.

