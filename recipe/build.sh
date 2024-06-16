#!/usr/bin/env bash
set -ex

install_leiningen() {
  # Installs a leiningen package
  # $1: Installation PREFIX, $2: leiningen package path, $3: leiningen version
  # This is a modified install script from the leiningen package
  local _prefix=$1
  local _leiningen_pkg_dir=$2

  lib_dir="${_prefix}/lib"
  bin_dir="${_prefix}/bin"

  leiningen_lib_dir="${lib_dir}/leiningen"

  mkdir -p "${bin_dir}" "${leiningen_lib_dir}/libexec"

  install -m644 "${_leiningen_pkg_dir}"/leiningen-*-standalone.jar "${leiningen_lib_dir}/libexec"
  install -m755 "${SRC_DIR}"/leiningen-src/bin/lein-pkg "${bin_dir}/lein"

  sed -i -e 's@/usr/share/java@\${CONDA_PREFIX}/lib/leiningen/libexec@g' "${bin_dir}"/lein
}

# --- Main ---

# Install the latest conda version of leiningen
# mamba install -y leiningen
install_leiningen "${PREFIX}" "${SRC_DIR}"/leiningen-jar "${PKG_VERSION}"

# Create bootstrap from source and extract the THIRD-PARTY.txt file
cd "${SRC_DIR}"/leiningen-src/leiningen-core
  lein bootstrap > _lein_bootstrap.log 2>&1
  mvn license:add-third-party -Dlicense.thirdPartyFile=THIRD-PARTY.txt > _lein_license.log 2>&1
cd "${SRC_DIR}"

# Copy the license files to the recipe directory
cp "${SRC_DIR}"/leiningen-src/leiningen-core/target/generated-sources/license/THIRD-PARTY.txt "${RECIPE_DIR}"/THIRD-PARTY.txt
cp "${SRC_DIR}"/leiningen-src/COPYING "${RECIPE_DIR}"/COPYING

# Use bootstrap to build the leiningen package
cd "${SRC_DIR}"/leiningen-src && bin/lein uberjar && cd "${SRC_DIR}"

install_leiningen "${PREFIX}" "${SRC_DIR}"/leiningen-src/target "${PKG_VERSION}"
