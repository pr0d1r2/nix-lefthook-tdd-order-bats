#!/usr/bin/env bats

setup() {
    load "${BATS_LIB_PATH}/bats-support/load.bash"
    load "${BATS_LIB_PATH}/bats-assert/load.bash"

    SCRIPT="$BATS_TEST_DIRNAME/../../spec-path-for-file.sh"
}

@test "script file exists" {
    [ -f "$SCRIPT" ]
}

@test "scripts/ prefix stripped for test path" {
    run bash "$SCRIPT" "scripts/build/deploy.sh"
    assert_success
    assert_line --index 0 "tests/build/deploy.bats"
}

@test "non-scripts path keeps dir" {
    run bash "$SCRIPT" "fragments/mount.sh"
    assert_success
    assert_line --index 0 "tests/fragments/mount.bats"
}

@test "underscore stem produces both candidates" {
    run bash "$SCRIPT" "scripts/build/my_tool.sh"
    assert_success
    assert_line --index 0 "tests/build/my-tool.bats"
    assert_line --index 1 "tests/build/my_tool.bats"
}

@test "hyphen-only stem produces single candidate" {
    run bash "$SCRIPT" "scripts/build/my-tool.sh"
    assert_success
    assert_output "tests/build/my-tool.bats"
}

@test "top-level script outside scripts/" {
    run bash "$SCRIPT" "helper.sh"
    assert_success
    assert_line --index 0 "tests/./helper.bats"
}
