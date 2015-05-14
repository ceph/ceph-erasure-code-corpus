#!/bin/bash -ex
#
# Copyright (C) 2014, 2015 Red Hat <contact@redhat.com>
# Copyright (C) 2015 FUJITSU LIMITED
#
# Author: Loic Dachary <loic@dachary.org>
# Authro: Miyamae, Takeshi <miyamae.takeshi@jp.fujitsu.com>
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
: ${JERASURE_VARIANTS:=generic sse3 sse4}
: ${MYDIR:=--base $(dirname $0)}

while read k m c ; do
    for stripe_width in $STRIPE_WIDTHS ; do
        ceph_erasure_code_non_regression --stripe-width $stripe_width --plugin shec --parameter technique=multiple --parameter k=$k --parameter m=$m --parameter c=$c $ACTION $VERBOSE $MYDIR
    done
done <<EOF
1 1 1
2 1 1
3 2 1
3 2 2
3 3 2
4 1 1
4 2 2
4 3 2
5 2 1
6 3 2
6 4 2
6 4 3
7 2 1
8 3 2
8 4 2
8 4 3
9 4 2
9 5 3
12 7 4
EOF

while read k m l ; do
    for stripe_width in $STRIPE_WIDTHS ; do
        ceph_erasure_code_non_regression --stripe-width $stripe_width --plugin lrc --parameter k=$k --parameter m=$m --parameter l=$l $ACTION $VERBOSE $MYDIR
    done
done <<EOF
2 2 2
4 2 3
8 4 3
EOF

if ceph_erasure_code --plugin_exists isa ; then
    while read k m ; do
        for technique in reed_sol_van cauchy ; do
            for stripe_width in $STRIPE_WIDTHS ; do
                ceph_erasure_code_non_regression --stripe-width $stripe_width --plugin isa --parameter technique=$technique --parameter k=$k --parameter m=$m $ACTION $VERBOSE $MYDIR
            done
        done
    done <<EOF
2 1
3 1
3 2
4 2
4 3
7 3
7 4
8 3
8 4
9 3
9 4
EOF
fi

while read k m ; do
    for stripe_width in $STRIPE_WIDTHS ; do
        for technique in cauchy_good cauchy_orig ; do
            for alignment in '' '--parameter jerasure-per-chunk-alignment=true' ; do
                ceph_erasure_code_non_regression --stripe-width $stripe_width --parameter packetsize=32 --plugin jerasure --parameter technique=$technique --parameter k=$k --parameter m=$m $alignment $ACTION $VERBOSE $MYDIR
            done
        done
    done
done <<EOF
2 1
3 1
3 2
4 2
4 3
7 3
7 4
7 5
8 3
8 4
9 3
9 4
9 5
9 6
EOF

while read k m ; do
    for stripe_width in $STRIPE_WIDTHS ; do
        for alignment in '' '--parameter jerasure-per-chunk-alignment=true' ; do
            ceph_erasure_code_non_regression --stripe-width $stripe_width --plugin jerasure --parameter technique=reed_sol_van --parameter k=$k --parameter m=$m $alignment $ACTION $VERBOSE $MYDIR
        done
    done
done <<EOF
2 1
3 1
3 2
4 2
4 3
7 3
7 4
7 5
8 3
8 4
9 3
9 4
9 5
9 6
EOF

for k in $(seq 2 6) ; do
    for stripe_width in $STRIPE_WIDTHS ; do
        for technique in reed_sol_r6_op liberation blaum_roth liber8tion ; do
            for alignment in '' '--parameter jerasure-per-chunk-alignment=true' ; do
                ceph_erasure_code_non_regression --stripe-width $stripe_width --parameter packetsize=32 --plugin jerasure --parameter technique=$technique --parameter k=$k --parameter m=2 $alignment $ACTION $VERBOSE $MYDIR
            done
        done
    done
done
