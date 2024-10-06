import logging
import os
import sys
import time
from typing import Any

import numpy.typing as npt
from vidgear.gears import CamGear

log = logging.getLogger(__name__)


class ReconnectingCamGear:
    __slots__ = ("cam_address", "reset_attempts", "reset_delay_initial", "source")

    def __init__(
        self, cam_address: str, reset_attempts: int = 50, reset_delay_initial: int = 1
    ) -> None:
        log.info(f"URL: {cam_address.rpartition("@")[-1]}")
        self.cam_address = cam_address
        self.reset_attempts = reset_attempts
        self.reset_delay_initial = reset_delay_initial
        self._initialize_cam_gear()

    def _initialize_cam_gear(self) -> None:
        for i in range(1, self.reset_attempts):
            try:
                self.source = CamGear(
                    source=self.cam_address,
                    logging=bool(os.getenv("VIDGEAR_LOGGING")) or False,
                    THREAD_TIMEOUT=60,
                ).start()
            except RuntimeError as e:
                if (
                    "Source is invalid, CamGear failed to initialize stream on this source"  # noqa:E501
                    in str(e)
                ):
                    log.debug(f"Reconnecting attempt {i} error: {e!r}")
                    time.sleep(self.reset_delay_initial * i * i)
                    continue
                raise
            else:
                return
        sys.exit("Can not connect to the source.")

    def read(self) -> npt.NDArray[Any]:
        for i in range(1, self.reset_attempts):
            frame: npt.NDArray[Any] | None = self.source.read()
            if frame is not None:
                return frame
            self.source.stop()
            log.info(f"Frame is None. Re-connection attempt: {i}.")
            time.sleep(self.reset_delay_initial * i)
            self._initialize_cam_gear()
        raise RuntimeError(
            f"After {self.reset_attempts} reconnecting "
            + "attempts still can not read a frame."
        )

    def stop(self) -> None:
        if self.source is not None:
            self.source.stop()
