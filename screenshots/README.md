# Screenshots

Add screenshots of your running SIEM here. Recruiters and professors want visual proof it works.

## Recommended screenshots to take:

1. **kibana-discover.png** — Kibana Discover tab showing live log events flowing in
2. **kibana-index-pattern.png** — The index pattern setup screen (logs-*)
3. **elasticsearch-indices.png** — Terminal output of `curl localhost:9200/_cat/indices?v` showing your indices
4. **systemctl-status.png** — All four services running (`systemctl status elasticsearch logstash kibana filebeat`)
5. **auth-log-search.png** — A Kibana search filtered to `auth.log` events (SSH logins, sudo commands)

## How to take screenshots in VMware:

- **From VM:** `gnome-screenshot` or `scrot filename.png` (install with `sudo apt install scrot`)
- **From host:** Use Snipping Tool / Snip & Sketch on Windows, then drag into the screenshots/ folder

## Naming convention:

Use lowercase-with-hyphens: `kibana-discover-2024.png`
