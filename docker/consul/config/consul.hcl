datacenter = "dc1"
data_dir = "/consul/data"
bind_addr = "0.0.0.0"
server = true
bootstrap_expect = 1
log_level = "WARN"
ui_config {
  enabled = true
}

# Ensure data persistence with valid Consul options
performance {
  raft_multiplier = 1
}