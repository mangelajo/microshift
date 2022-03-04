#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
get="${SCRIPT_DIR}/../../../pkg/release/get.sh"

ARCHITECTURES=${ARCHITECTURES:-"arm64 amd64"}
BASE_VERSION=${BASE_VERSION:-$("${get}" base)}
OUTPUT_DIR=${OUTPUT_DIR:-$(pwd)/archive}

TMP_DIR=$(mktemp -d)

mkdir -p "${OUTPUT_DIR}"
chown a+rw "${OUTPUT_DIR}"

for arch in $ARCHITECTURES; do
    images=$("${get}" images $arch)
    storage="${TMP_DIR}/${arch}/containers"
    mkdir -p "${storage}"
    echo "Pulling images for architecture ${arch} ==================="
    for image in $images; do
        echo pulling $image @$arch
        # some imported images are armhfp instead of arm
        podman pull --arch $arch --root "${storage}" "${image}" || echo "FALLBACK! ${arch}" && \
          [ "${arch}" == "arm" ] && podman pull --arch armhfp --root "${TMP_DIR}/${arch}" "${image}"
    done

    echo ""
    echo "Packing tarball for architecture ${arch} =================="
    pushd ${storage}
    tar cfj "${OUTPUT_DIR}/microshift-containers-${BASE_VERSION}-${arch}.tar.bz2" .
    chown a+rw "${OUTPUT_DIR}/microshift-containers-${BASE_VERSION}-${arch}.tar.bz2"
    popd
    rm -rf ${storage}
done




