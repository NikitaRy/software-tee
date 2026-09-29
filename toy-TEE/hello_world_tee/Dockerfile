# OP-TEE (ARM TrustZone) в QEMU v8 — итоговое окружение.
# Сборка образа:  podman build --build-arg UID=$(id -u) -t optee .
FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive LANG=C.UTF-8 LC_ALL=C.UTF-8

# Зависимости OP-TEE + то, что пришлось доставлять вручную:
#   tmux             — make run-only открывает в нём консоли Normal/Secure World
#   qemu-system-arm  — готовый qemu-system-aarch64 вместо сборки QEMU из исходников
#   libgnutls28-dev  — нужен U-Boot для утилиты mkeficapsule
RUN apt-get update && apt-get install -y \
      acpica-tools autoconf automake bc bison build-essential ccache cpio curl \
      device-tree-compiler e2tools expect file flex gdisk git libattr1-dev \
      libcap-ng-dev libfdt-dev libglib2.0-dev libgmp-dev libgnutls28-dev \
      libmpc-dev libncurses-dev libpixman-1-dev libslirp-dev libssl-dev libtool \
      make mtools netcat-openbsd ninja-build python3-cryptography \
      python3-pyelftools python3-serial python3-venv python-is-python3 \
      qemu-system-arm repo rsync swig tmux unzip uuid-dev wget xz-utils zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# repo/git требуют имя и почту
RUN git config --system user.name dev && git config --system user.email dev@localhost

# tmux: bash по умолчанию и прокрутка колесом мыши
RUN printf 'set -g default-shell /bin/bash\nset -g mouse on\n' > /etc/tmux.conf

# Пользователь с uid хоста (для --userns=keep-id) и bash в качестве шелла.
# В ubuntu:24.04 uid 1000 занят пользователем ubuntu — убираем его.
ARG UID=1000
RUN userdel -r ubuntu 2>/dev/null || true \
 && useradd -m -s /bin/bash -u ${UID} dev

# Короткие команды для всех шагов (optee-setup, optee-build, optee-run)
COPY optee-aliases.sh /etc/profile.d/optee-aliases.sh
RUN echo '. /etc/profile.d/optee-aliases.sh' >> /home/dev/.bashrc

USER dev
WORKDIR /home/dev
CMD ["bash"]