#!/usr/bin/env bats

setup() {
    load "${BATS_LIB_PATH}/bats-support/load.bash"
    load "${BATS_LIB_PATH}/bats-assert/load.bash"

    WORKDIR="$(mktemp -d)"
    CONFIRM="$WORKDIR/confirm.sh"
    cat > "$WORKDIR/confirm-target.sh" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$FRAGMENTS_DIR|$ASSEMBLE_SCRIPT|$DETECT_SCRIPT|$SETTING_SRC|$CONFIRM_REV"
SH
    chmod +x "$WORKDIR/confirm-target.sh"
    sed \
        -e "s|@FRAGMENTS_DIR@|fragments|" \
        -e "s|@ASSEMBLE_SCRIPT@|assemble|" \
        -e "s|@DETECT_SCRIPT@|detect|" \
        -e "s|@SETTING_SRC@|setting|" \
        -e "s|@CONFIRM_SCRIPT@|$WORKDIR/confirm-target.sh|" \
        -e "s|@CONFIRM_REV@|revision|" \
        "$BATS_TEST_DIRNAME/../../confirm.sh" > "$CONFIRM"
}

teardown() {
    rm -rf "$WORKDIR"
}

@test "delegates to the configured confirmation script" {
    run bash "$CONFIRM"
    assert_success
}

@test "exports configured values to the confirmation script" {
    run bash "$CONFIRM"
    assert_success
    assert_output "fragments|assemble|detect|setting|revision"
}
