# Screenshots — Elastic SIEM Lab

Visual proof of the full ELK stack running and ingesting logs.

---

## Kibana — Live Log Discovery
![Kibana Discover](kibana-discover.png)
> Kibana Discover showing 3,366 hits — real-time log events flowing from Filebeat through Logstash into Elasticsearch. Index pattern: `filebeat-*`.

---

## Elasticsearch — Running
![Elasticsearch Running](elasticsearch-running.png)
> `systemctl status elasticsearch` — active (running), enabled on boot. Using 2.9GB RAM, confirming a healthy production-style deployment.

---

## Elasticsearch — Indices Confirmed
![Elasticsearch Indices](elasticsearch-indices.png)
> `curl localhost:9200/_cat/indices?v` — confirms Filebeat index exists with 11,721 documents ingested. Pipeline is working end-to-end.

---

## Logstash — Running
![Logstash Running](logstash-running.png)
> `systemctl status logstash` — active (running). Logs confirm Beats input listener started and pipeline is live.

---

## Kibana — Running
![Kibana Running](kibana-running.png)
> `systemctl status kibana` — active (running), enabled on boot. Accessible at port 5601.

---

## Filebeat — Running
![Filebeat Running](filebeat-running.png)
> `systemctl status filebeat` — active (running). Shipping logs every 30 seconds (monitoring heartbeat visible in logs).

---

## Filebeat — Running in VM
![Filebeat VM](filebeat-running-vm.png)
> Filebeat status confirmed inside the Ubuntu VM terminal.

---

## SSH — Running
![SSH Status](ssh-status.png)
> `systemctl status ssh` — OpenSSH server active, listening on port 22. Remote access to the SIEM box is enabled.
