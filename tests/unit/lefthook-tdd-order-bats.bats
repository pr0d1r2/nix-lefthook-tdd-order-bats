#!/usr/bin/env bats
# shellcheck disable=SC2030,SC2031

setup() {
    load "${BATS_LIB_PATH}/bats-support/load.bash"
    load "${BATS_LIB_PATH}/bats-assert/load.bash"

    TMP="$BATS_TEST_TMPDIR/repo"
    mkdir -p "$TMP"
    git init "$TMP" >/dev/null 2>&1
    cd "$TMP" || return 1
    git config user.email "test@test.com"
    git config user.name "Test"
    # create initial commit as base
    echo "init" > README.md
    git add README.md
    git commit -m "init" >/dev/null 2>&1
    git tag base
    export LEFTHOOK_TDD_BASE_REF="base"
}

@test "exits 0 when LEFTHOOK_TDD_ALLOW_GAP is set" {
    export LEFTHOOK_TDD_ALLOW_GAP=1
    run lefthook-tdd-order-bats
    assert_success
}

@test "exits 0 when no commits above base" {
    run lefthook-tdd-order-bats
    assert_success
}

@test "exits 0 when base ref does not exist" {
    export LEFTHOOK_TDD_BASE_REF="nonexistent-ref"
    run lefthook-tdd-order-bats
    assert_success
}

@test "exits 0 when script has matching bats in same commit" {
    mkdir -p scripts/foo tests/foo
    echo '#!/bin/bash' > scripts/foo/bar.sh
    echo '#!/usr/bin/env bats' > tests/foo/bar.bats
    git add scripts/foo/bar.sh tests/foo/bar.bats
    git commit -m "add script with spec" >/dev/null 2>&1
    run lefthook-tdd-order-bats
    assert_success
}

@test "fails when script lacks matching bats" {
    mkdir -p scripts/foo
    echo '#!/bin/bash' > scripts/foo/bar.sh
    git add scripts/foo/bar.sh
    git commit -m "add script without spec" >/dev/null 2>&1
    run lefthook-tdd-order-bats
    assert_failure
    assert_output --partial "tdd-order:"
    assert_output --partial "missing"
    assert_output --partial "ERROR"
}

@test "strips scripts/ prefix for test path" {
    mkdir -p scripts/build tests/build
    echo '#!/bin/bash' > scripts/build/run.sh
    echo '#!/usr/bin/env bats' > tests/build/run.bats
    git add scripts/build/run.sh tests/build/run.bats
    git commit -m "add build script with spec" >/dev/null 2>&1
    run lefthook-tdd-order-bats
    assert_success
}

@test "non-scripts paths keep full dir in test path" {
    mkdir -p fragments tests/fragments
    echo '#!/bin/bash' > fragments/mount.sh
    echo '#!/usr/bin/env bats' > tests/fragments/mount.bats
    git add fragments/mount.sh tests/fragments/mount.bats
    git commit -m "add fragment with spec" >/dev/null 2>&1
    run lefthook-tdd-order-bats
    assert_success
}

@test "normalizes underscores to hyphens in stem" {
    mkdir -p scripts/build tests/build
    echo '#!/bin/bash' > scripts/build/my_tool.sh
    echo '#!/usr/bin/env bats' > tests/build/my-tool.bats
    git add scripts/build/my_tool.sh tests/build/my-tool.bats
    git commit -m "add underscore script with hyphen spec" >/dev/null 2>&1
    run lefthook-tdd-order-bats
    assert_success
}

@test "respects LEFTHOOK_TDD_EXCLUDE" {
    export LEFTHOOK_TDD_EXCLUDE="scripts/vendor/*"
    mkdir -p scripts/vendor
    echo '#!/bin/bash' > scripts/vendor/lib.sh
    git add scripts/vendor/lib.sh
    git commit -m "add vendor script" >/dev/null 2>&1
    run lefthook-tdd-order-bats
    assert_success
}

@test "respects LEFTHOOK_TDD_PATHS" {
    export LEFTHOOK_TDD_PATHS=":(glob)lib/**/*.sh"
    mkdir -p scripts/foo
    echo '#!/bin/bash' > scripts/foo/bar.sh
    git add scripts/foo/bar.sh
    git commit -m "add script outside scan paths" >/dev/null 2>&1
    run lefthook-tdd-order-bats
    assert_success
}

@test "respects baseline file" {
    mkdir -p scripts/foo
    echo '#!/bin/bash' > scripts/foo/old.sh
    git add scripts/foo/old.sh
    git commit -m "old script" >/dev/null 2>&1
    # set baseline to current HEAD
    git rev-parse HEAD > .tdd-order-baseline
    git add .tdd-order-baseline
    git commit -m "add baseline" >/dev/null 2>&1
    run lefthook-tdd-order-bats
    assert_success
}

@test "custom baseline file via LEFTHOOK_TDD_BASELINE" {
    export LEFTHOOK_TDD_BASELINE=".my-baseline"
    mkdir -p scripts/foo
    echo '#!/bin/bash' > scripts/foo/old.sh
    git add scripts/foo/old.sh
    git commit -m "old script" >/dev/null 2>&1
    git rev-parse HEAD > .my-baseline
    git add .my-baseline
    git commit -m "add baseline" >/dev/null 2>&1
    run lefthook-tdd-order-bats
    assert_success
}

@test "LEFTHOOK_TDD_SPEC_DIR overrides test directory" {
    export LEFTHOOK_TDD_SPEC_DIR="tests/unit"
    mkdir -p scripts/foo tests/unit/foo
    echo '#!/bin/bash' > scripts/foo/bar.sh
    echo '#!/usr/bin/env bats' > tests/unit/foo/bar.bats
    git add scripts/foo/bar.sh tests/unit/foo/bar.bats
    git commit -m "add script with spec in tests/unit" >/dev/null 2>&1
    run lefthook-tdd-order-bats
    assert_success
}

@test "LEFTHOOK_TDD_SPEC_DIR fails when spec in wrong dir" {
    export LEFTHOOK_TDD_SPEC_DIR="tests/unit"
    mkdir -p scripts/foo tests/foo
    echo '#!/bin/bash' > scripts/foo/bar.sh
    echo '#!/usr/bin/env bats' > tests/foo/bar.bats
    git add scripts/foo/bar.sh tests/foo/bar.bats
    git commit -m "spec in tests/ not tests/unit/" >/dev/null 2>&1
    run lefthook-tdd-order-bats
    assert_failure
}

@test "LEFTHOOK_TDD_SRC_STRIP empty disables prefix stripping" {
    export LEFTHOOK_TDD_SRC_STRIP=""
    mkdir -p scripts/foo tests/scripts/foo
    echo '#!/bin/bash' > scripts/foo/bar.sh
    echo '#!/usr/bin/env bats' > tests/scripts/foo/bar.bats
    git add scripts/foo/bar.sh tests/scripts/foo/bar.bats
    git commit -m "keep scripts/ in test path" >/dev/null 2>&1
    run lefthook-tdd-order-bats
    assert_success
}

@test "LEFTHOOK_TDD_SRC_STRIP custom prefix" {
    export LEFTHOOK_TDD_SRC_STRIP="lib"
    mkdir -p lib/utils tests/utils
    echo '#!/bin/bash' > lib/utils/helper.sh
    echo '#!/usr/bin/env bats' > tests/utils/helper.bats
    git add lib/utils/helper.sh tests/utils/helper.bats
    git commit -m "strip lib/ prefix" >/dev/null 2>&1
    run lefthook-tdd-order-bats
    assert_success
}

@test "combined SPEC_DIR and SRC_STRIP for nix-config layout" {
    export LEFTHOOK_TDD_SPEC_DIR="tests/unit"
    export LEFTHOOK_TDD_SRC_STRIP=""
    mkdir -p scripts/lefthook tests/unit/scripts/lefthook
    echo '#!/bin/bash' > scripts/lefthook/check.sh
    echo '#!/usr/bin/env bats' > tests/unit/scripts/lefthook/check.bats
    git add scripts/lefthook/check.sh tests/unit/scripts/lefthook/check.bats
    git commit -m "nix-config layout" >/dev/null 2>&1
    run lefthook-tdd-order-bats
    assert_success
}
