FROM ubuntu:latest
# Create a directory inside the container to mount the data volume
RUN mkdir -p /soft-serve/scripts

# Copy the scripts into the scripts directory
COPY scripts /soft-serve/scripts

# Set the working directory to the new directory
WORKDIR /soft-serve

# Update image and install necessary packages
RUN apt update && apt upgrade -y && apt install curl gpg -y

# Install Soft Serve as the non-root user
RUN curl -fsSL https://repo.charm.sh/apt/gpg.key | gpg --dearmor -o /etc/apt/keyrings/charm.gpg
RUN echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | tee /etc/apt/sources.list.d/charm.list
RUN apt update && apt install soft-serve -y 

# Create a non-root user and group 'softserve'
RUN groupadd -r softserve && useradd -m -r -g softserve softserve

# Set ownership and permissions for the installation directory
RUN chown -R softserve:softserve /soft-serve
RUN chmod -R 755 /soft-serve

USER softserve

# Change working directory to the user's home directory
# WORKDIR /home/softserve

# Expose ports
# SSH
EXPOSE 23231/tcp
# HTTP
EXPOSE 23232/tcp
# Stats
EXPOSE 23233/tcp
# Git
EXPOSE 9418/tcp

CMD ["/soft-serve/scripts/entrypoint.sh"]
