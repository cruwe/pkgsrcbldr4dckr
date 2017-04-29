#!/usr/bin/env bash

if [ -z ${RELEASE+x} ]; then
    echo "RELEASE is unset, cannnot continue without."
    exit 1
fi

GENDISTLOC=/pub/NetBSD/packages/distfiles/
MNTPNT=${MNTPNT:-/data}
OS=$(cat /etc/os-release | grep -Ei ^id | awk -F= '{print $2}')
VERSION=$(cat /etc/os-release | grep -Ei ^version_id | awk -F= '{print $2}')

export PREFIX=/usr/pbulk

export ALLOW_VULNERABLE_PACKAGES=${ALLOW_VULNERABLE_PACKAGES:-yes}
export FAILOVER_FETCH=${FAILOVER_FETCH:-yes}
export FETCH_USING=${FETCH_SUING:-curl}
export MAKE_JOBS=${MAKE_JOBS:-4}
export MASTER_SITE_OVERRIDE=${MASTER_SITE_OVERRIDE:-ftp://ftp2.fr.NetBSD.org/$GENDISTLOC}
export SKIP_LICENSE_CHECK=${SKIP_LICENSE_CHECK:-yes}
export DISTDIR=${MNTPNT}/distfiles
export PACKAGES=${MNTPNT}/packages/${RELEASE}/${OS}/${VERSION}/pbulk
export WRKOBJDIR=${MNTPNT}/wrk/${RELEASE}/${OS}/${VERSION}/pbulk-bootstrap
export PKGSRCDIR=${MNTPNT}/pkgsrc

BOOTSTRAPTGZDIR=${PACKAGES}/boostrap

for dir in \
    ${DISTDIR} \
    ${PACKAGES} \
    ${BOOTSTRAPTGZDIR} \
    ${WRKOBJDIR}
do
    mkdir -p $dir
done

cd ${PKGSRCDIR}
git clean -fd
git checkout pkgsrc_${RELEASE}

cd ${PKGSRCDIR}/bootstrap
./cleanup
./bootstrap \
    --abi=64 \
    --prefix=${PREFIX}
./cleanup

export PATH=${PREFIX}/sbin:${PREFIX}/bin:${PATH}

cd ${PKGSRCDIR}/pkgtools/pbulk
bmake clean-depends clean package-install clean-depends clean

tar -czf \
    ${BOOTSTRAPTGZDIR}/pbulkbootstrap-${RELEASE}-${OS}-${VERSION}.tgz \
    ${PREFIX}

chown -R pbulk:pbulk ${MNTPNT}
