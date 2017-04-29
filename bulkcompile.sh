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
export WRKOBJDIR=${MNTPNT}/wrk/${RELEASE}/${OS}/${VERSION}
export PKGSRCDIR=${MNTPNT}/pkgsrc

BOOTSTRAPTGZDIR=${PACKAGES}/boostrap

tar -xzf \
    ${BOOTSTRAPTGZDIR}/pbulkbootstrap-${RELEASE}-${OS}-${VERSION}.tgz

cat >> /usr/pbulk/etc/pbulk.conf << EOF
#
# ----------------------------------------------------------------------------
# ------------------------- Inserting overrides ------------------------------
# ----------------------------------------------------------------------------
#
master_mode=no
#
prefix=${PREFIX}
bulklog=${MNTPNT}/bulklog/${RELEASE}/${OS}/${VERSION}
packages=${MNTPNT}/packages/${RELEASE}/${OS}/${VERSION}
pkgdb=\${prefix}/var/db/pkgdb
pkgsrc=${MNTPNT}/pkgsrc
varbase=\${prefix}/var
#
loc=\${bulklog}/meta
#
bootstrapkit=${BOOTSTRAPTGZDIR}/${PREFIX_s}bootstrap-${RELEASE}-${OS}-${VERSION}.tgz
#
mail=:
rsync=:
reuse_scan_results=no
limited_list=/pkglist
make=\${prefix}/bin/bmake
EOF

mkdir -p ${MNTPNT}/packages/${RELEASE}/${OS}/${VERSION}/All
chown -R pbulk:pbulk ${MNTPNT}

/usr/pbulk/bin/bulkbuild