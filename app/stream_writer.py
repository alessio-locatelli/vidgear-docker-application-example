import os
import time
from pathlib import Path
from typing import Any, Self

import cv2
from vidgear.gears import WriteGear

from app.reconnecting_cam_gear import ReconnectingCamGear


class StreamWriter:
    __slots__ = ("stream", "writer")

    def __enter__(self) -> Self:
        self.stream = ReconnectingCamGear(cam_address=os.environ["RTSP_URL"])
        video_output_path = Path(os.environ["SAVE_LOCATION"])
        video_output_path.mkdir(exist_ok=True, parents=True)

        # NOTE: The following FFmpeg parameters are given as an example and are not
        # guaranteed to follow best practice. Please refer to the FFmpeg documentation
        # to select the most appropriate parameters for your use case.
        output_params = {
            "-c:v": "libx264",
            "-map": 0,
            "-segment_time": 10 * 60,
            "-sc_threshold": 0,
            "-force_key_frames": "expr:gte(t,n_forced*9)",
            "-clones": ["-f", "segment"],
        }

        self.writer = WriteGear(
            output=str(video_output_path / f"{int(time.time())}out%03d.mp4"),
            compression_mode=True,
            logging=bool(os.getenv("VIDGEAR_LOGGING")) or False,
            **output_params,
        )
        return self

    def __exit__(self, *_: Any) -> None:
        cv2.destroyAllWindows()
        self.stream.stop()
        self.writer.close()

    def start(self) -> None:
        while True:
            frame = self.stream.read()
            self.writer.write(frame)


if __name__ == "__main__":
    with StreamWriter() as surveillance:
        surveillance.start()
