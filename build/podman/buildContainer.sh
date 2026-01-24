podman build -t rfnm-builder .

# Copy container to root
podman save rfnm-builder -o /tmp/rfnm-builder.tar  
sudo podman load -i /tmp/rfnm-builder.tar
rm /tmp/rfnm-builder.tar 