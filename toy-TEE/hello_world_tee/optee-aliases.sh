export JOBS=${JOBS:-2}
alias optee-setup='mkdir -p ~/optee && cd ~/optee && repo init --depth=1 -u https://github.com/OP-TEE/manifest.git -m qemu_v8.xml && repo sync -c --no-tags -j$JOBS && make -C build toolchains -j$JOBS'
alias optee-build='cd ~/optee/build && make -j$JOBS -k 2>&1 | tee ~/build.log | tail -40; ls -la ~/optee/out/bin'
alias optee-run='cd ~/optee/build && make run-only QEMU_BIN=/usr/bin/qemu-system-aarch64'
case $- in *i*) echo "optee-setup -> optee-build -> tmux -> optee-run   (JOBS=$JOBS)";; esac