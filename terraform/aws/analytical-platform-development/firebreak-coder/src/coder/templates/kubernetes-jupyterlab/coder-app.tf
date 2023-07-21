resource "coder_app" "jupyterlab" {
  agent_id     = coder_agent.main.id
  slug         = "jupyter"
  display_name = "JupyterLab"
  url          = "http://localhost:8888"
  icon         = "/icon/jupyter.svg"
  subdomain    = true
  share        = "owner"

  healthcheck {
    url       = "http://localhost:8888/healthz"
    interval  = 5
    threshold = 10
  }
}
