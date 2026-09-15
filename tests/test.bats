setup() {
  set -eu -o pipefail
  export DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )/.."
  export TESTDIR=~/tmp/test-manticoresearch
  mkdir -p $TESTDIR
  export PROJNAME=test-manticoresearch
  export MANTICORE_TEST_IMAGE=${MANTICORE_TEST_IMAGE:-manticoresearch/manticore:25.0.0}
  export DDEV_NON_INTERACTIVE=true
  ddev delete -Oy ${PROJNAME} >/dev/null 2>&1 || true
  cd "${TESTDIR}"
  ddev config --project-name=${PROJNAME}
  ddev start -y >/dev/null
}

health_checks() {
  # Do something useful here that verifies the add-on
  ddev exec "sleep 20 && curl -s manticoresearch:9308"
}

teardown() {
  set -eu -o pipefail
  cd ${TESTDIR} || ( printf "unable to cd to ${TESTDIR}\n" && exit 1 )
  ddev delete -Oy ${PROJNAME} >/dev/null 2>&1
  [ "${TESTDIR}" != "" ] && rm -rf ${TESTDIR}
}

@test "install from directory" {
  set -eu -o pipefail
  cd ${TESTDIR}
  echo "# ddev add-on get ${DIR} with project ${PROJNAME} in ${TESTDIR} ($(pwd))" >&3
  ddev add-on get ${DIR}
  ddev restart
  health_checks
  # A fresh install must run the version pinned in docker-compose.manticoresearch.yaml,
  # not a floating tag.
  default_image=$(sed -n 's|.*MANTICORESEARCH_DOCKER_IMAGE:-\(.*\)}.*|\1|p' "${DIR}/docker-compose.manticoresearch.yaml")
  echo "# pinned default is ${default_image}" >&3
  [ -n "${default_image}" ]
  [[ "${default_image}" != *:latest ]]
  run docker inspect --format '{{.Config.Image}}' ddev-${PROJNAME}-manticoresearch
  [ "$status" -eq 0 ]
  [ "$output" = "${default_image}" ]
}

# bats test_tags=release
@test "install from release" {
  set -eu -o pipefail
  cd ${TESTDIR} || ( printf "unable to cd to ${TESTDIR}\n" && exit 1 )
  echo "# ddev add-on get bricebou/ddev-manticoresearch with project ${PROJNAME} in ${TESTDIR} ($(pwd))" >&3
  ddev add-on get bricebou/ddev-manticoresearch
  ddev restart >/dev/null
  health_checks
}

@test "pin a specific Manticore Search version" {
  set -eu -o pipefail
  cd ${TESTDIR}
  echo "# pinning ${MANTICORE_TEST_IMAGE} with project ${PROJNAME} in ${TESTDIR} ($(pwd))" >&3
  ddev add-on get ${DIR}
  ddev dotenv set .ddev/.env.manticoresearch --manticoresearch-docker-image=${MANTICORE_TEST_IMAGE}
  ddev restart
  health_checks
  run docker inspect --format '{{.Config.Image}}' ddev-${PROJNAME}-manticoresearch
  [ "$status" -eq 0 ]
  [ "$output" = "${MANTICORE_TEST_IMAGE}" ]
}
