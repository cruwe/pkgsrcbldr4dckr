#!/usr/bin/env bash

if [ -z ${RELEASE+x} ]; then
    echo "RELEASE is unset, cannnot continue without."
    exit 1
fi

GENDISTLOC=/pub/NetBSD/packages/distfiles/
MNTPNT=${MNTPNT:-/data}
OS=$(cat /etc/os-release | grep -Ei ^id | awk -F= '{print $2}')
VERSION=$(cat /etc/os-release | grep -Ei ^version_id | awk -F= '{print $2}')

export PREFIX=${PREFIX:-/usr/pkg}
export PREFIX_s=$(echo $PREFIX | cut -c 2- | sed 's/\//-/g')

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

export PATH=/usr/pbulk/sbin:/usr/pbulk/bin:/usr/sbin:/usr/bin:/sbin:/bin

tar -xzf \
    ${BOOTSTRAPTGZDIR}/pbulkbootstrap-${RELEASE}-${OS}-${VERSION}.tgz

if [ $? -ne 0 ]; then
    echo "pbulk for ${RELEASE}-${OS}-${VERSION} not available."
    echo "cannot continue."
    exit 1
fi

cd ${MNTPNT}/pkgsrc
git clean -fd
git checkout pkgsrc_${RELEASE}

cd ${MNTPNT}/pkgsrc/bootstrap
./cleanup
./bootstrap \
    --abi=64 \
    --prefix=${PREFIX} \
    --pkgdbdir=${PREFIX}/var/db/pkgdb \
    --pkginfodir=info \
    --pkgmandir=man \
    --sysconfdir=${PREFIX}/etc \
    --varbase=${PREFIX}/var 
./cleanup

export PATH=${PREFIX}/sbin:${PREFIX}/bin:/usr/sbin:/usr/bin:/sbin:/bin

# TODO: package pkgin with failing digest on pkgin package upstream
# cd ${PKGSRCDIR}/pkgtools/pkgin
# bmake clean-depends clean package-install clean-depends clean

tar -czf \
    ${BOOTSTRAPTGZDIR}/${PREFIX_s}bootstrap-${RELEASE}-${OS}-${VERSION}.tgz \
    ${PREFIX}

chown -R pbulk:pbulk ${MNTPNT}
