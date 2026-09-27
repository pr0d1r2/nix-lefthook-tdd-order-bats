#!/usr/bin/env bats

setup() {
    load "${BATS_LIB_PATH}/bats-support/load.bash"
    load "${BATS_LIB_PATH}/bats-assert/load.bash"

    SCRIPT="$BATS_TEST_DIRNAME/../../confirm.sh"
}

@test "exports configured values and runs the confirmation script" {
    rendered="$BATS_TEST_TMPDIR/confirm.sh"
    recorder="$BATS_TEST_TMPDIR/record-env.sh"
    output="$BATS_TEST_TMPDIR/output"

    cat > "$recorder" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$FRAGMENTS_DIR" "$ASSEMBLE_SCRIPT" "$DETECT_SCRIPT" \
    "$SETTING_SRC" "$CONFIRM_SCRIPT" "$CONFIRM_REV" > "$CONFIRM_OUTPUT"
SH
    chmod +x "$recorder"
    sed \
        -e "s|@FRAGMENTS_DIR@|fragments|" \
        -e "s|@ASSEMBLE_SCRIPT@|assemble|" \
        -e "s|@DETECT_SCRIPT@|detect|" \
        -e "s|@SETTING_SRC@|setting|" \
        -e "s|@CONFIRM_SCRIPT@|$recorder|" \
        -e "s|@CONFIRM_REV@|revision|" \
        "$SCRIPT" > "$rendered"

    export CONFIRM_OUTPUT="$output"
    run bash "$rendered"

    assert_success
    run cat "$output"
    assert_output $'fragments\nassemble\ndetect\nsetting\n'"$recorder"$'\nrevision'
}
