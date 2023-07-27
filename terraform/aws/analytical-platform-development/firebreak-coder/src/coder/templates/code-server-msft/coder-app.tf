resource "coder_app" "code_server" {
  agent_id     = coder_agent.main.id
  slug         = "msft-code-server"
  display_name = "msft-code-server"
  icon         = "/icon/code.svg"
  url          = "http://localhost:8080?folder=/home/coder"
  subdomain    = true
  share        = "owner"

  healthcheck {
    url       = "http://localhost:8080/healthz"
    interval  = 3
    threshold = 10
  }
}
