# Notes

```sh
docker run -it --rm \
  --name qemu \
  -p 8080:8006 \
  -p 2222:2222 \
  -v ${PWD:-.}/qemu:/storage \
  -e KVM=N \
  -e TPM=Y \
  -e BOOT=fedora \
  -e RAM_SIZE=8G \
  --stop-timeout 120 localhost/qemu
```

```
docker run -it --rm \
  --name qemu \
  -e BOOT=alpine \
  -p 8080:8006 \
  -p 2222:2222 \
  -v ${PWD:-.}/qemu:/storage \
  -e KVM=N \
  -e TPM=N \
  -e RAM_SIZE=8G \
  -u 1001 \
  --stop-timeout 120 localhost/qemu
```
