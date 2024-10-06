# syntax = docker/dockerfile:1

FROM fedora:40 AS builder
WORKDIR /


# Python
ENV PYTHONUNBUFFERED=1 \
    PYTHONFAULTHANDLER=1 \
    # Prevents python creating .pyc files
    PYTHONDONTWRITEBYTECODE=1 \
    \
    # Pip
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1 \
    \
    # Poetry
    POETRY_VIRTUALENVS_CREATE=true \
    # Make poetry install to this location
    POETRY_HOME="/opt/poetry" \
    # Make poetry create the virtual environment in the project's root (it gets named `.venv`)
    POETRY_VIRTUALENVS_IN_PROJECT=true \
    POETRY_VIRTUALENVS_OPTIONS_NO_PIP=true \
    POETRY_VIRTUALENVS_OPTIONS_NO_SETUPTOOLS=true \
    # Paths
    # The "opt/" directory is a common place to put a project. See https://www.pathname.com/fhs/pub/fhs-2.3.html#OPTADDONAPPLICATIONSOFTWAREPACKAGES
    PYSETUP_PATH="/opt/pysetup" \
    VENV_PATH="/opt/pysetup/.venv"

# Prepend Poetry and venv to path
ENV PATH="$POETRY_HOME/bin:$VENV_PATH/bin:$PATH"

# Set the SHELL option -o pipefail before RUN with a pipe in (https://github.com/hadolint/hadolint/wiki/DL4006).
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN \
    dnf -y upgrade --refresh && dnf install -y -q \
    python3 \
    gcc \
    gcc-c++ \
    python-devel \
    \
    && python3 -m ensurepip --upgrade \
    && python3 -m pip install virtualenv==20.26.6 \
    # Install Poetry.
    && curl -sSL https://install.python-poetry.org | POETRY_VERSION=1.8.3 python3 - && poetry --version \
    \
    # Remove anything that is not required anymore.
    && dnf -y clean all && rm -rf /var/cache/yum
WORKDIR /opt/pysetup
COPY --link pyproject.toml poetry.lock ./
RUN poetry install --no-interaction --no-ansi --no-root --only main


FROM fedora:40 AS deploy
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV \
    POETRY_VIRTUALENVS_CREATE=true \
    POETRY_HOME="/opt/poetry" \
    POETRY_VIRTUALENVS_IN_PROJECT=true \
    POETRY_VIRTUALENVS_OPTIONS_NO_PIP=true \
    POETRY_VIRTUALENVS_OPTIONS_NO_SETUPTOOLS=true \
    PYSETUP_PATH="/opt/pysetup" \
    VENV_PATH="/opt/pysetup/.venv"

# Prepend Poetry and venv to path
ENV PATH="$POETRY_HOME/bin:$VENV_PATH/bin:$PATH"

WORKDIR /opt/pysetup
RUN \
    dnf -y install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    && dnf -y install https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm \
    && dnf -y install 'dnf-command(config-manager)' \
    && dnf -y config-manager --enable fedora-cisco-openh264 \
    && dnf -y upgrade --refresh \
    && dnf -y install ffmpeg openh264 \
    # Clean up.
    && dnf -y clean all && rm -rf /var/cache/yum

COPY --link --from=builder $PYSETUP_PATH/.venv $PYSETUP_PATH/.venv

ARG USERNAME=nonroot
ARG USER_UID=1000
ARG USER_GID=$USER_UID
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && chown -R $USER_UID:$USER_GID $PYSETUP_PATH \
    # Create the volume directory beforehand:
    # https://github.com/docker/compose/issues/3270#issuecomment-363478501
    && mkdir /opt/records && chown -R $USER_UID:$USER_GID /opt/records
COPY --link --chown=$USER_UID:$USER_GID app ./app
USER $USERNAME
