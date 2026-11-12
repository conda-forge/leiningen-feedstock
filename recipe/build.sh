#!/usr/bin/env bash
set -ex

install_leiningen() {
  # Installs a leiningen package
  # $1: Installation PREFIX, $2: leiningen package path, $3: leiningen version
  # $4: jar directory as written into the lein script (literal text)
  # This is a modified install script from the leiningen package
  local _prefix=$1
  local _leiningen_pkg_dir=$2
  local _version=$3
  local _jar_dir=$4

  lib_dir="${_prefix}/lib"
  bin_dir="${_prefix}/bin"

  leiningen_lib_dir="${lib_dir}/leiningen"

  mkdir -p "${bin_dir}" "${leiningen_lib_dir}/libexec"

  install -m644 "${_leiningen_pkg_dir}/leiningen-${_version}-standalone.jar" "${leiningen_lib_dir}/libexec"
  install -m755 "${SRC_DIR}"/leiningen-src/bin/lein-pkg "${bin_dir}/lein"

  sed -i -e "s@/usr/share/java@${_jar_dir}@g" "${bin_dir}"/lein
  sed -i -E "s/^(export )?LEIN_VERSION=.*/\1LEIN_VERSION=\"${_version}\"/" "${bin_dir}"/lein
  grep -q "LEIN_VERSION=\"${_version}\"" "${bin_dir}"/lein
}

# --- Main ---

# Bootstrap lein from the conda leiningen in BUILD_PREFIX (never lands in PREFIX).
# CONDA_PREFIX is overridden because the lein script locates its jar via
# ${CONDA_PREFIX}/lib/leiningen/libexec, and during conda-build that is the host prefix.
blein() { CONDA_PREFIX="${BUILD_PREFIX}" "${BUILD_PREFIX}/bin/lein" "$@"; }
blein version

# Create bootstrap from source and extract the THIRD-PARTY.txt file
cd "${SRC_DIR}"/leiningen-src/leiningen-core
  sed -i -E "s/[0-9.]+-SNAPSHOT/${PKG_VERSION}/g" pom.xml project.clj
  blein bootstrap > _lein_bootstrap.log 2>&1 || { echo "lein bootstrap failed, log tail:"; tail -n 200 _lein_bootstrap.log; exit 1; }
  mvn license:add-third-party -Dlicense.thirdPartyFile=THIRD-PARTY.txt > _lein_license.log 2>&1 || { echo "mvn license:add-third-party failed, log tail:"; tail -n 200 _lein_license.log; exit 1; }
cd "${SRC_DIR}"

# Use bootstrap to build the leiningen package
cd "${SRC_DIR}"/leiningen-src && sed -i -E "s/[0-9.]+-SNAPSHOT/${PKG_VERSION}/g" bin/lein project.clj && bin/lein uberjar && cd "${SRC_DIR}"

install_leiningen "${PREFIX}" "${SRC_DIR}"/leiningen-src/target "${PKG_VERSION}" '${CONDA_PREFIX}/lib/leiningen/libexec'
