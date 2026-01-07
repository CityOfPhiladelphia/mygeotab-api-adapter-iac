// This file is a combination of https://github.com/grafana/alloy-scenarios/tree/main/linux and https://github.com/grafana/alloy-scenarios/tree/main/docker-monitoring

// ###############################
// #### Metrics Configuration ####
// ###############################

// This block relabels metrics coming from node_exporter to add standard labels
discovery.relabel "integrations_node_exporter" {
  targets = prometheus.exporter.unix.integrations_node_exporter.targets

  rule {
    // Set the instance label to the hostname of the machine
    target_label = "instance"
    replacement  = constants.hostname
  }

  rule {
    // Set the app name
    target_label = "app_name"
    replacement = sys.env("APP_NAME")
  }

  rule {
    // Set the env name
    target_label = "env_name"
    replacement = sys.env("ENV_NAME")
  }

  rule {
    // Set a standard job name for all node_exporter metrics
    target_label = "job"
    replacement = "integrations/node_exporter"
  }
}

// Configure the node_exporter integration to collect system metrics
prometheus.exporter.unix "integrations_node_exporter" {
  // Disable unnecessary collectors to reduce overhead
  disable_collectors = ["ipvs", "btrfs", "infiniband", "xfs", "zfs"]
  enable_collectors = ["meminfo"]

  filesystem {
    // Exclude filesystem types that aren't relevant for monitoring
    fs_types_exclude     = "^(autofs|binfmt_misc|bpf|cgroup2?|configfs|debugfs|devpts|devtmpfs|tmpfs|fusectl|hugetlbfs|iso9660|mqueue|nsfs|overlay|proc|procfs|pstore|rpc_pipefs|securityfs|selinuxfs|squashfs|sysfs|tracefs)$"
    // Exclude mount points that aren't relevant for monitoring
    mount_points_exclude = "^/(dev|proc|run/credentials/.+|sys|var/lib/docker/.+)($|/)"
    // Timeout for filesystem operations
    mount_timeout        = "5s"
  }

  netclass {
    // Ignore virtual and container network interfaces
    ignored_devices = "^(veth.*|cali.*|[a-f0-9]{15})$"
  }

  netdev {
    // Exclude virtual and container network interfaces from device metrics
    device_exclude = "^(veth.*|cali.*|[a-f0-9]{15})$"
  }

}

// Define how to scrape metrics from the node_exporter
prometheus.scrape "integrations_node_exporter" {
scrape_interval = "15s"
  // Use the targets with labels from the discovery.relabel component
  targets    = discovery.relabel.integrations_node_exporter.output
  // Send the scraped metrics to the relabeling component
  forward_to = [prometheus.remote_write.prod.receiver]
}

// Configure a prometheus.remote_write component to send metrics to a Prometheus server.
prometheus.remote_write "prod" {
  endpoint {
    url = "https://citygeo-grafana.phila.gov:9090/api/v1/push"

    headers = {
      "X-Scope-OrgID" = "citygeo",
    }

    basic_auth {
      username = sys.env("PROMETHEUS_USER")
      password = sys.env("PROMETHEUS_PASSWORD")
    }
  }
}

// ###############################
// #### Logging Configuration ####
// ###############################

loki.source.journal "logs_integrations_integrations_node_exporter_journal_scrape" {
  // Only collect logs from the last 24 hours
  max_age       = "24h0m0s"
  // Apply relabeling rules to the logs
  relabel_rules = discovery.relabel.logs_integrations_integrations_node_exporter_journal_scrape.rules
  // Send logs to the local Loki instance
  forward_to    = [loki.write.prod.receiver]
}

local.file_match "logs_integrations_integrations_node_exporter_direct_scrape" {
  path_targets = [{
    // Target 10.30.80.106 for log collection
    __address__ = "10.30.80.106",
    // Collect standard system logs
    __path__    = "/var/log/{syslog,messages,*.log}",
    // Add instance label with hostname
    instance    = constants.hostname,
    // Add job label for logs
    job         = "integrations/node_exporter",
  }]
}

// Define relabeling rules for systemd journal logs
discovery.relabel "logs_integrations_integrations_node_exporter_journal_scrape" {
  targets = []

  rule {
    // Extract systemd unit information into a label
    source_labels = ["__journal__systemd_unit"]
    target_label  = "unit"
  }

  rule {
    // Extract boot ID information into a label
    source_labels = ["__journal__boot_id"]
    target_label  = "boot_id"
  }

  rule {
    // Extract transport information into a label
    source_labels = ["__journal__transport"]
    target_label  = "transport"
  }

  rule {
    // Extract log priority into a level label
    source_labels = ["__journal_priority_keyword"]
    target_label  = "level"
  }

  rule {
    // Set the app name
    target_label = "app_name"
    replacement = sys.env("APP_NAME")
  }

  rule {
    // Set the env name
    target_label = "env_name"
    replacement = sys.env("ENV_NAME")
  }
}

// Collect logs from files for node_exporter
loki.source.file "logs_integrations_integrations_node_exporter_direct_scrape" {
  // Use targets defined in local.file_match
  targets    = local.file_match.logs_integrations_integrations_node_exporter_direct_scrape.targets
  // Send logs to the local Loki instance
  forward_to = [loki.write.prod.receiver]
}

loki.write "prod" {
  endpoint {
    url = "https://citygeo-grafana.phila.gov:3100/loki/api/v1/push"
    tenant_id = "citygeo"

    basic_auth {
      username = sys.env("LOKI_USER")
      password = sys.env("LOKI_PASSWORD")
    }
  }
}
