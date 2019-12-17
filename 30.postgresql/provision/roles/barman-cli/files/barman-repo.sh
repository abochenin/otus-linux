#!/usr/bin/env bash
#####################################################################
# 2ndQuadrant RPM repository: installation shell script
#
# Repository: dl/default/release at 2ndquadrant.com
#
# Copyright (C) 2018 2ndQuadrant Ltd (www.2ndQuadrant.com)
#####################################################################

set -eEu

INSTALLATION_REPORT="$(mktemp -t 2ndq_packages_installation.log.XXXXX)"

# The installation script is wrapped in the "do_install()" function
# for two reasons:
# 1. protect against partial download of the file (and subsequent
#    execution - e.g. "curl ... | sh")
# 2. redirect stderr channel to a temporary file
# some protection against only getting part of the file during the
do_install() {

    # Enable trace inside the function
    set -x

    # Default connection timeout = 30 seconds.
    # You can override it with the SECONDQ_TIMEOUT environment variable.
    # For example, you can set it to 10 seconds as follows:
    # export SECONDQ_TIMEOUT = 10
    SECONDQ_TIMEOUT=${SECONDQ_TIMEOUT:-30}

    # Check distribution compatibility
    
    if [ ! -d /etc/yum.repos.d/ ]
    then
        echo "Cannot install RPM packages: incompatible distribution"
        return
    fi
    
    
    #
    # Install the repository public GPG key
    #
    
    rpm_key_file="/etc/pki/rpm-gpg/RPM-GPG-KEY-2NDQ-DL-DEFAULT"
    cat > "$rpm_key_file" <<EOF
-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v1

mQINBFqpNU0BEAC6tFZf3Vt5FB4sG0pDeomVypnxTudww/bFm4ZWg3NsP4tnhaao
ngO32/ExyyhLbYSIVsQIHYPEamzLJbJwCDTxMLE2x7NrXbC0xeel0Ku7YQcL5VZC
EWNJapAIgynao5nTlPMxV4U5TT2BWT2FlbyyRUCn9ng6VvTuxMczF9yKtP4ITKwy
DWe4EGJmxumFyiMzjH3QN96PT+kUfPgDbf6oQfCCZAauVzTpXmkWpt1bw5BlDpXF
gEx7bLYufaHobVmchrsE+fNGRTvByeWp5sXE+YCeOJWFwL5chSRSP/M5xMFR3C8C
k6OVT0z2h7a/8ftZMIa3L5Fuc6oQxPY3XZe0JP4jOfqhBw0I2IEffW9yEKqh6GkS
VK1JaDFnS3KkCKXvTgNCOuZENfSC44rycrOfnPz9r3l4WQgUyOL8FdLq/oas/G97
M2DiUQYK9GkQkjarNzIzklfPByqkNSUHr7uSV0NiWQdlrm47uxg2ILC+k9aiAl5N
/3zR0W2pyjp9C1FqAY/VFa9m1+WNmWHHmFEgEU2mORymb9/WqUGpJ033zZqmQrwC
PkbmYjY2zYgY2vaPHpaUa+sJb7Blph334NOUI9Z37+vaHP/4VlmH8XikRZ58kSPk
i5npwKUwWhrA794Smq27DB1GlFYG3L2whkVuAm37tW/1G85hPynZAPLAWwARAQAB
tD5QdWJsaWMgcmVwb3NpdG9yeSBzaWduaW5nIGtleSAybmRRdWFkcmFudCA8Y2lA
Mm5kcXVhZHJhbnQuY29tPokCPgQTAQIAKAUCWqk1TQIbAwUJA8JnAAYLCQgHAwIG
FQgCCQoLBBYCAwECHgECF4AACgkQmQTNS9a68MP/AhAAhSP7I5XVlQaDk0G/JSAx
jkeeJCBTM2tBF7YmgBHqEetPg39zNGfXKsQA9nJ4+TS+GaCPWeG6gP7nH40vgbkP
16Tz4179hv/sDmpTjqFhDucU2RJLB4mraZRTjDRSatfRsdcczP6tRCUYJbwVFvVx
ztq46h4gSzW0N/Afl9twqO3p3hNPmbMBqAtZtX9xk0mv0mjF/fO+kneGJ3VxR1W0
TuoBTMQRzqLdVmvqqrxhsnH9pf3c4CDLRtz/FPRBWcTryb/JSf2xA/D+gE4dqTRv
tmY4jyAx5tRe5J0TWy7ghGeQiowTgpVJZ9qLp0vZcX+G2hMn1T7g6ftV/shIp5+Z
PmzGZqw+Dx5V1Npcm0KGmc0/QGN/1MPRiq4YQk1CQWIEc5N3s6FkwTsWmEdve8T4
PTo4/XSzRBT7M3AdSBhKzl4i3IPct5ld8pP1wWk9u/fMnGnbmGERQGohvigsxqc/
KMi29dG8iGP5gJNEbEvNyD4LtfeQYhB3vI/RI5CRrBCKnqdZlJemPiS08w8zJrny
WogrXlkE4pGu22Ryh+jI4jtusBktPU8Kxx1bKtDkr9EAqYazWSu9Ha/w79loFpfN
RYH5/+4dehDUjcrluUcN7hshJijqlkgUctjLYOdleJHKAgSX06+6oeu74SH/i+z6
6SUYZxf80izYErwrFxhxlx8=
=V6ND
-----END PGP PUBLIC KEY BLOCK-----
EOF
    chmod 644 "$rpm_key_file"
    
    
    #
    # Add the RPM repository to the system
    #
    yum_repo_file="/etc/yum.repos.d/2ndquadrant-dl-default-release-pg11.repo"
    # The only system we officially support that does not have /etc/os-release is centos/rhel 5/6, so centos works
    distribution=$(. /etc/os-release 2> /dev/null && echo $ID || echo centos)

    # Detect https_proxy variable to include it in single repository definitions
    proxy=""
    if [ -n "${https_proxy:-}" ]
    then
      proxy="proxy=${https_proxy}"
    elif [ -n "${HTTPS_PROXY:-}" ]
    then
      proxy="proxy=${HTTPS_PROXY}"
    fi

    cat > "$yum_repo_file" <<EOF
[2ndquadrant-dl-default-release-pg11]
name=2ndQuadrant packages (PG11) for \$releasever - \$basearch
baseurl=https://dl.2ndquadrant.com/default/release/rpm/packages/${distribution}/\$releasever/\$basearch/11/
enabled=1
gpgcheck=1
gpgkey=file://${rpm_key_file}
${proxy}

[2ndquadrant-dl-default-release-pg11-debug]
name=2ndQuadrant packages (PG11) for \$releasever - \$basearch - Debug
baseurl=https://dl.2ndquadrant.com/default/release/rpm/dbg_packages/${distribution}/\$releasever/\$basearch/11/
enabled=1
gpgcheck=1
gpgkey=file://${rpm_key_file}
${proxy}

[2ndquadrant-dl-default-release-pg11-source]
name=2ndQuadrant packages (PG11) for \$releasever - \$basearch - Source
baseurl=https://dl.2ndquadrant.com/default/release/rpm/src_packages/${distribution}/\$releasever/\$basearch/11/
enabled=0
gpgcheck=1
gpgkey=file://${rpm_key_file}
${proxy}
EOF
    chmod 644 "$yum_repo_file"
    
    echo
    echo "Installation finished: 2ndquadrant.com RPM repository dl/default/release for PG11"
    set +x
}

installation_failed() {
    set +x
    echo "FATAL: Installation failed, either your platform is not easily detectable"
    echo "or it is not supported by this installer script. Please open a support ticket"
    echo "and attach the log file '${INSTALLATION_REPORT}' to receive more detailed"
    echo "information"
    exit 1
}

trap 'installation_failed' ERR

if [ "$(id -u)" -ne 0 ]
then
    echo "Cannot update system: this script must be executed as root"
    exit 1
fi

do_install 2> "${INSTALLATION_REPORT}"
rm -f "${INSTALLATION_REPORT}"

# End of repository installation script ;)
