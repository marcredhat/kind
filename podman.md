

https://www.redhat.com/sysadmin/behind-scenes-podman

```bash
mkdir containers

cat > ~/Containerfile << _EOF
FROM ubi8
RUN echo “in buildah container”
_EOF

podman run --device /dev/fuse -v ~/Containerfile:/Containerfile:Z -v ~/containers:/var/lib/containers:Z buildah buildah bud /
```
