# [vidgear](https://github.com/abhiTronix/vidgear) containerized demo project

A production-ready example of a minimal Docker application.

## How to start

This repository is intended to provide a minimal working example of code for your future production-ready application, not to be used on its own, as all the code does is write a stream to a file.

However, if you want to run the current code for learning purposes or to write a stream to a file:

1. Define `.env` file:

   ```env
   RTSP_URL=
   SAVE_LOCATION=/opt/records
   ```

2. `docker compose up`
