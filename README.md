# VooSu for Android, iOS, Linux, Windows, and macOS

**VooSu** - is an open system for messaging and collaboration, focused on simplicity and
scalability.

---

## Supported Platforms

- **Linux**
- **Android** 7.0+
- **iOS** 13.0+
- **macOS** Catalina 10.15+
- **Windows** 10+

---

[Server version repository](https://github.com/voo-su/VooSu-server)

---

## Build Instructions

#### Linux & Android

To build for **Linux** and **Android** using Docker:

```bash
docker build -f Dockerfile --target linux-build -t flutter-linux .
docker run --rm -e TARGETS=linux,android -v ./out:/opt/voosu/out flutter-linux
```

#### Windows

Building for **Windows** requires a **Windows host**:

```bash
docker build -f Dockerfile-windows --target windows-build -t flutter-windows .
docker run --rm -v .\out:C:\voosu\out flutter-windows
```
