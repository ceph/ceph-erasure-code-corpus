ceph-erasure-code-corpus
========================

Objects erasure encoded by Ceph

To check all prior sets of data from the ceph src/directory:



To check a set of data from the ceph/src directory:

$READ_WRITE_CLONE/ceph-erasure-code-corpus/$(git describe)/non-regression.sh

To create a new set of data from the ceph/src directory:

ACTION=--create $READ_WRITE_CLONE/ceph-erasure-code-corpus/$(git describe)/non-regression.sh
