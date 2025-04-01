import docker
import os

client = docker.from_env()
print(client.containers.list())
