#!/usr/bin/env bats

setup() {
    load "${BATS_LIB_PATH}/bats-support/load.bash"
    load "${BATS_LIB_PATH}/bats-assert/load.bash"

    SCRIPT="$BATS_TEST_DIRNAME/../../is-excluded-path.sh"
}

@test "script file exists" {
    [ -f "$SCRIPT" ]
}

@test "empty patterns returns not excluded" {
    run bash "$SCRIPT" "scripts/foo/bar.sh" ""
    assert_failure
}

@test "no pattern arg returns not excluded" {
    run bash "$SCRIPT" "scripts/foo/bar.sh"
    assert_failure
}

@test "matching glob pattern returns excluded" {
    run bash "$SCRIPT" "scripts/vendor/lib.sh" "scripts/vendor/*"
    assert_success
}

@test "non-matching pattern returns not excluded" {
    run bash "$SCRIPT" "scripts/app/main.sh" "scripts/vendor/*"
    assert_failure
}

@test "multiple colon-separated patterns" {
    run bash "$SCRIPT" "lib/helper.sh" "scripts/vendor/*:lib/*"
    assert_success
}

@test "multiple patterns no match" {
    run bash "$SCRIPT" "src/main.sh" "scripts/vendor/*:lib/*"
    assert_failure
}
