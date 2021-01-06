

https://www.redhat.com/sysadmin/behind-scenes-podman


podman login registry.redhat.io --username <email address you registered for the free developer account>
Password:
Login Succeeded!


```bash
mkdir containers

cat > ~/Containerfile << _EOF
FROM registry.access.redhat.com/ubi8/ubi 
RUN echo “in buildah container”
_EOF

podman run --device /dev/fuse -v ~/Containerfile:/Containerfile:Z -v ~/containers:/var/lib/containers:Z buildah buildah bud /
```
