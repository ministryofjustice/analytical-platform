resource "coder_agent" "main" {
  os                     = "linux"
  arch                   = "amd64"
  startup_script_timeout = 180
  startup_script         = <<-EOT
    set -e

    cd /tmp
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    cd -

    #####################
    export TARGET_DIRECTORY="/opt/vscode"

    sudo apt-get update

    sudo apt-get install -y jq

    sudo mkdir --parent $${TARGET_DIRECTORY} || exit 1

    export codeServerVersion=$(curl --silent https://update.code.visualstudio.com/api/commits/stable/server-linux-x64-web | jq -r 'first')

    sudo curl https://az764295.vo.msecnd.net/stable/$${codeServerVersion}/vscode-server-linux-x64-web.tar.gz \
      --output /tmp/vscode-server-linux-x64-web.tar.gz

    sudo tar --strip-components=1 -xf /tmp/vscode-server-linux-x64-web.tar.gz -C /opt/vscode

    mkdir --parents $${HOME}/.vscode-server/extensions || exit 1

    mkdir --parents $${HOME}/.vscode-server/data || exit 1

    /opt/vscode/bin/code-server \
      --accept-server-license-terms \
      --without-connection-token \
      --telemetry-level off \
      --host 0.0.0.0 \
      --port 8080 \
      --extensions-dir $${HOME}/.vscode-server/extensions \
      --user-data-dir $${HOME}/.vscode-server/data
  EOT

  metadata {
    display_name = "CPU Usage"
    key          = "0_cpu_usage"
    script       = "coder stat cpu"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "Memory Usage"
    key          = "1_mem_usage"
    script       = "coder stat mem"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "Home Disk"
    key          = "3_home_disk"
    script       = "coder stat disk --path $${HOME}"
    interval     = 60
    timeout      = 1
  }

  metadata {
    display_name = "CPU Usage (Host)"
    key          = "4_cpu_usage_host"
    script       = "coder stat cpu --host"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "Memory Usage (Host)"
    key          = "5_mem_usage_host"
    script       = "coder stat mem --host"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "Load Average (Host)"
    key          = "6_load_host"
    # get load avg scaled by number of cores
    script   = <<EOT
      echo "`cat /proc/loadavg | awk '{ print $1 }'` `nproc`" | awk '{ printf "%0.2f", $1/$2 }'
    EOT
    interval = 60
    timeout  = 1
  }
}
