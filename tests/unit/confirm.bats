#!/usr/bin/env bats

setup() {
    load "${BATS_LIB_PATH}/bats-support/load.bash"
    load "${BATS_LIB_PATH}/bats-assert/load.bash"

    WORKDIR="$(mktemp -d)"
    CONFIRM="${WORKDIR}/confirm.sh"
    sed "s|@CONFIRM_SCRIPT@|$WORKDIR/delegate.sh|" confirm.sh > "$CONFIRM"
    cat > "${WORKDIR}/delegate.sh" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "confirm delegated"
SH
    chmod +x "$CONFIRM" "${WORKDIR}/delegate.sh"
}

teardown() {
    rm -rf "$WORKDIR"
}

@test "delegates confirmation to the configured script" {
    run bash "$CONFIRM"
    assert_success
    assert_output "confirm delegated"
}
