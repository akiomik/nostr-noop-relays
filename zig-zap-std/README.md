## Build with Docker

NOTE: Currently only aarch64 is supported.

```bash
docker build -t zig-zap-std .
docker run -it --rm --name zig-zap-std -p 8080:8080 zig-zap-std
```
