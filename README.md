# SFTPGo Unofficial Docker image

This is an unofficial image for [SFTPGo](https://github.com/drakkan/sftpgo), the fully featured and highly configurable SFTP server

This image is primarily for my personal needs, feel free however to use it if you find it handy. The Dockerfile is based on the alpine Dockerfile example available in SFTPGo's repository. 

Keep in mind that this image is always built from the latest source code available at the time when I push a tag to this repo, because the SFTPGo project is evolving rapidly and I'm comfortable with using bleeding-edge features. Tags of this image always resemble the date of the build.

## Building

This image is built automatically and published on Docker Hub when I push tag to this repo.

To build the image manually I use this exact command:

From bash:

```
env DATE="20200225" IMAGE_VERSION=1 \
docker build -t sftpgo:${DATE}-v${IMAGE_VERSION} .
```

From powershell:

```
$env:DATE="20200225"; $env:IMAGE_VERSION="1";
docker build -t sftpgo:$env:DATE-v$env:IMAGE_VERSION .
```

