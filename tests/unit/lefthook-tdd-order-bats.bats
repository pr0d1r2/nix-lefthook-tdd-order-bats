#!/usr/bin/env bats
# shellcheck disable=SC2030,SC2031

setup() {
    load "${BATS_LIB_PATH}/bats-support/load"
    load "${BATS_LIB_PATH}/bats-assert/load"

    unset LEFTHOOK_TDD_SPEC_DIR
    unset LEFTHOOK_TDD_SRC_STRIP
    unset LEFTHOOK_TDD_PATHS
    unset LEFTHOOK_TDD_EXCLUDE
    unset LEFTHOOK_TDD_BASELINE
    unset LEFTHOOK_TDD_ALLOW_GAP

    TMP="$BATS_TEST_TMPDIR/repo"
    mkdir -p "$TMP"
    git init "$TMP" >/dev/null 2>&1
    cd "$TMP" || return 1
    git config user.email "test@test.com"
    git config user.name "Test"
    echo "init" > README.md
    git add README.md
    git commit -m "init" >/dev/null 2>&1
    git tag base
    export LEFTHOOK_TDD_BASE_REF="base"
}
@test "allow gap" {
    export LEFTHOOK_TDD_ALLOW_GAP=1
    run lefthook-tdd-order-bats
    assert_success
}
@test "no commits" {
    run lefthook-tdd-order-bats
    assert_success
}
@test "missing base" {
    export LEFTHOOK_TDD_BASE_REF="nonexistent-ref"
    run lefthook-tdd-order-bats
    assert_success
}
@test "matching bats" {
    mkdir -p scripts/foo tests/foo
    echo '#!/bin/bash' > scripts/foo/bar.sh
    echo '#!/usr/bin/env bats' > tests/foo/bar.bats
    git add scripts/foo/bar.sh tests/foo/bar.bats
    git commit -m "add script with spec" >/dev/null 2>&1
    run lefthook-tdd-order-bats
    assert_success
}
@test "missing bats fails" {
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
@test "range unit spec" {
    echo '#!/bin/bash' > x.sh
    mkdir -p tests/unit
    echo '#!/usr/bin/env bats' > tests/unit/x.bats
    git add x.sh tests/unit/x.bats
    git commit -m "add script with unit spec" >/dev/null 2>&1
    run lefthook-tdd-order-bats
    assert_success
}
@test "range candidates" {
    echo '#!/bin/bash' > x.sh
    git add x.sh
    git commit -m "add script without spec" >/dev/null 2>&1
    run lefthook-tdd-order-bats
    assert_failure
    assert_output --partial "tests/x.bats, tests/unit/x.bats"
}
@test "strips scripts prefix" {
    mkdir -p scripts/build tests/build
    echo '#!/bin/bash' > scripts/build/run.sh
    echo '#!/usr/bin/env bats' > tests/build/run.bats
    git add scripts/build/run.sh tests/build/run.bats
    git commit -m "add build script with spec" >/dev/null 2>&1
    run lefthook-tdd-order-bats
    assert_success
}
@test "keeps non-scripts dir" {
    mkdir -p fragments tests/fragments
    echo '#!/bin/bash' > fragments/mount.sh
    echo '#!/usr/bin/env bats' > tests/fragments/mount.bats
    git add fragments/mount.sh tests/fragments/mount.bats
    git commit -m "add fragment with spec" >/dev/null 2>&1
    run lefthook-tdd-order-bats
    assert_success
}
@test "normalizes underscores" {
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
@test "custom spec directory" {
    export LEFTHOOK_TDD_SPEC_DIR="tests/unit"
    mkdir -p scripts/foo tests/unit/foo
    echo '#!/bin/bash' > scripts/foo/bar.sh
    echo '#!/usr/bin/env bats' > tests/unit/foo/bar.bats
    git add scripts/foo/bar.sh tests/unit/foo/bar.bats
    git commit -m "add script with spec in tests/unit" >/dev/null 2>&1
    run lefthook-tdd-order-bats
    assert_success
}
@test "wrong spec directory fails" {
    export LEFTHOOK_TDD_SPEC_DIR="tests/unit"
    mkdir -p scripts/foo tests/foo
    echo '#!/bin/bash' > scripts/foo/bar.sh
    echo '#!/usr/bin/env bats' > tests/foo/bar.bats
    git add scripts/foo/bar.sh tests/foo/bar.bats
    git commit -m "spec in tests/ not tests/unit/" >/dev/null 2>&1
    run lefthook-tdd-order-bats
    assert_failure
}
@test "empty source strip" {
    export LEFTHOOK_TDD_SRC_STRIP=""
    mkdir -p scripts/foo tests/scripts/foo
    echo '#!/bin/bash' > scripts/foo/bar.sh
    echo '#!/usr/bin/env bats' > tests/scripts/foo/bar.bats
    git add scripts/foo/bar.sh tests/scripts/foo/bar.bats
    git commit -m "keep scripts/ in test path" >/dev/null 2>&1
    run lefthook-tdd-order-bats
    assert_success
}
@test "custom source strip" {
    export LEFTHOOK_TDD_SRC_STRIP="lib"
    mkdir -p lib/utils tests/utils
    echo '#!/bin/bash' > lib/utils/helper.sh
    echo '#!/usr/bin/env bats' > tests/utils/helper.bats
    git add lib/utils/helper.sh tests/utils/helper.bats
    git commit -m "strip lib/ prefix" >/dev/null 2>&1
    run lefthook-tdd-order-bats
    assert_success
}
@test "later spec commit" {
    mkdir -p scripts/foo
    echo '#!/bin/bash' > scripts/foo/bar.sh
    git add scripts/foo/bar.sh
    git commit -m "add script without spec" >/dev/null 2>&1
    mkdir -p tests/foo
    echo '#!/usr/bin/env bats' > tests/foo/bar.bats
    git add tests/foo/bar.bats
    git commit -m "add spec for bar" >/dev/null 2>&1
    run lefthook-tdd-order-bats
    assert_success
}
@test "nix layout" {
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
@test "staged no sh" {
    run lefthook-tdd-order-bats --staged notes.md config.yml
    assert_success
}
@test "staged empty" {
    run lefthook-tdd-order-bats --staged
    assert_success
}
@test "staged matching spec" {
    mkdir -p scripts/foo tests/foo
    echo '#!/usr/bin/env bats' > tests/foo/bar.bats
    git add tests/foo/bar.bats
    git commit -m "add spec first" >/dev/null 2>&1
    echo '#!/bin/bash' > scripts/foo/bar.sh
    run lefthook-tdd-order-bats --staged scripts/foo/bar.sh
    assert_success
}
@test "staged adjacent spec" {
    mkdir -p scripts/foo tests/foo
    echo '#!/bin/bash' > scripts/foo/bar.sh
    echo '#!/usr/bin/env bats' > tests/foo/bar.bats
    run lefthook-tdd-order-bats --staged scripts/foo/bar.sh tests/foo/bar.bats
    assert_success
}
@test "staged missing spec" {
    mkdir -p scripts/foo
    echo '#!/bin/bash' > scripts/foo/bar.sh
    run lefthook-tdd-order-bats --staged scripts/foo/bar.sh
    assert_failure
    assert_output --partial "tdd-order: staged"
}
@test "staged unit spec" {
    mkdir -p tests/unit
    echo '#!/usr/bin/env bats' > tests/unit/x.bats
    git add tests/unit/x.bats
    echo '#!/bin/bash' > x.sh
    run lefthook-tdd-order-bats --staged x.sh
    assert_success
}
@test "staged candidates" {
    echo '#!/bin/bash' > x.sh
    run lefthook-tdd-order-bats --staged x.sh
    assert_failure
    assert_output --partial "tests/x.bats, tests/unit/x.bats"
}
@test "staged: explicit spec directory uses only one candidate" {
    export LEFTHOOK_TDD_SPEC_DIR=spec
    mkdir -p tests/unit
    echo '#!/usr/bin/env bats' > tests/unit/x.bats
    echo '#!/bin/bash' > x.sh
    run lefthook-tdd-order-bats --staged x.sh
    assert_failure
    assert_output --partial "spec/x.bats"
    refute_output --partial "tests/unit/x.bats"
}
@test "staged: ignores old commits — only checks given files" {
    mkdir -p scripts/old
    echo '#!/bin/bash' > scripts/old/gap.sh
    git add scripts/old/gap.sh
    git commit -m "old script without spec" >/dev/null 2>&1
    run lefthook-tdd-order-bats --staged config.yml
    assert_success
}
@test "staged: respects LEFTHOOK_TDD_EXCLUDE" {
    export LEFTHOOK_TDD_EXCLUDE="scripts/vendor/*"
    mkdir -p scripts/vendor
    echo '#!/bin/bash' > scripts/vendor/lib.sh
    run lefthook-tdd-order-bats --staged scripts/vendor/lib.sh
    assert_success
}
@test "staged: respects LEFTHOOK_TDD_ALLOW_GAP" {
    export LEFTHOOK_TDD_ALLOW_GAP=1
    mkdir -p scripts/foo
    echo '#!/bin/bash' > scripts/foo/bar.sh
    run lefthook-tdd-order-bats --staged scripts/foo/bar.sh
    assert_success
}
@test "staged: filters non-.sh from mixed file list" {
    mkdir -p scripts/foo tests/foo
    echo '#!/bin/bash' > scripts/foo/bar.sh
    echo '#!/usr/bin/env bats' > tests/foo/bar.bats
    run lefthook-tdd-order-bats --staged scripts/foo/bar.sh README.md flake.nix
    assert_success
}
