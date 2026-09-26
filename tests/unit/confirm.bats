#!/usr/bin/env bats

setup() {
    script="$BATS_TEST_TMPDIR/confirm.sh"
    sed "s|@CONFIRM_SCRIPT@|$BATS_TEST_TMPDIR/confirm-command.sh|" \
        confirm.sh > "$script"
    cat > "$BATS_TEST_TMPDIR/confirm-command.sh" <<'EOF'
#!/usr/bin/env bash
echo confirmed
EOF
    chmod +x "$BATS_TEST_TMPDIR/confirm-command.sh"
}

@test "delegates confirmation to the configured confirm script" {
    run bash "$script"
    [ "$status" -eq 0 ]
    [ "$output" = "confirmed" ]
}
