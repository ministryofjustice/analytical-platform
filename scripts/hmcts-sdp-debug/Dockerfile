FROM public.ecr.aws/ubuntu/ubuntu:24.04@sha256:da20fb875cfefd317c49e7aaf3998d3e5ad42c5b20f34a0eec6dca2fe4fbb8f4

RUN <<EOF
apt-get update --yes

apt-get install --yes \
  curl \
  iputils-ping \
  netcat-openbsd
EOF
