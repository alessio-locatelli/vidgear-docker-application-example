# [vidgear](https://github.com/abhiTronix/vidgear) containerized demo project

A template / minimal working example that can be used as a starting point for creating a production-ready application.

## How to start

This repository is intended to provide a minimal working example of code for your future production-ready application, not to be used on its own, as all the code does is write a stream to a file.

However, if you want to run the current code for learning purposes:

1. Define `.env` file:

   ```env
   RTSP_URL=
   SAVE_LOCATION=/opt/records
   ```

2. `docker compose up`

## Related

- https://hub.docker.com/r/linuxserver/ffmpeg
- https://github.com/jrottenberg/ffmpeg
- https://github.com/AkashiSN/ffmpeg-docker
- https://hub.docker.com/r/intel/intel-optimized-ffmpeg
