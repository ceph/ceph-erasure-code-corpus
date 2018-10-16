#!/bin/bash
#
# Copyright (C) 2018 Indian Institute of Science <office.ece@iisc.ac.in>
#
# Author: Myna <mynaramana@gmail.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU Library Public License as published by
# the Free Software Foundation; either version 2, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Library Public License for more details.
#
: ${ACTION:=--check}
: ${STRIPE_WIDTHS:=4096 4651 8192 10000 65000 65536}
: ${VERBOSE:=} # VERBOSE=--debug-osd=20
: ${MYDIR:=--base $(dirname $0)}

TMP=$(mktemp -d)
trap "rm -fr $TMP" EXIT

function non_regression() {
    local action=$1
    shift

    if test $action != NOOP ; then
        ./ceph_erasure_code_non_regression $action "$@" || return 1
    fi
}

function verify_directories() {
    local base=$(dirname "$(head -1 $TMP/used)")
    ls "$base" | grep 'plugin=' | sort > $TMP/exist_sorted
    sed -e 's|.*/||' $TMP/used | sort > $TMP/used_sorted
    if ! cmp $TMP/used_sorted $TMP/exist_sorted ; then
        echo "The following directories contain a payload that should have been verified"
        echo "but they have not been. It probably means that a change in the script"
        echo "made it skip these directories. If the modification is intended, the directories"
        echo "should be removed."
        comm -13 $TMP/used_sorted $TMP/exist_sorted
        return 1
    fi
}

function test_clay() {
    while read k m d ; do
        for stripe_width in $STRIPE_WIDTHS ; do
            for technique in reed_sol_van; do
	        non_regression $ACTION --stripe-width $stripe_width --plugin clay --parameter scalar_mds=jerasure --parameter technique=$technique --parameter k=$k --parameter m=$m --parameter d=$d $VERBOSE $MYDIR || return 1
            done
        done
    done <<EOF
2 2 3
3 2 4
4 2 5
4 3 6
4 3 5
7 3 8
7 4 10
7 4 9
7 4 8
7 5 10
7 5 9
7 5 8
8 4 11
8 4 10
8 4 9
7 3 9
7 5 11
8 3 10
8 3 9
9 3 11
9 3 10
9 4 12
9 4 11
9 4 10
9 5 13
9 5 11
9 5 10
9 6 14
9 6 12
9 6 10
EOF
}

function run() {
    local all_funcs=$(set | sed -n -e 's/^\(test_[0-9a-z_]*\) .*/\1/p')
    local funcs=${@:-$all_funcs}
    PS4="$0":'$LINENO: ${FUNCNAME[0]} '
    set -x
    for func in $funcs ; do
        $func || return 1
    done
    if test "$all_funcs" = "$funcs" ; then
        verify_directories || return 1
    fi
}

run "$@" || exit 1
