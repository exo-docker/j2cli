#!/bin/bash
# Smoke tests of the image, usage: tests/smoke.sh [image] (default: exoplatform/j2cli:test)
set -u
IMAGE="${1:-exoplatform/j2cli:test}"
WORKDIR="$(mktemp -d)"
trap 'rm -rf "${WORKDIR}"' EXIT
FAILED=0

# the template is mounted on the same absolute path than on the host, like the ADT does
render() { # [-e VAR=value ...] -- <jinjanate options> <template>
  local _env=()
  while [ "$1" != "--" ]; do _env+=("$1"); shift; done; shift
  docker run --rm "${_env[@]}" -v "${WORKDIR}":"${WORKDIR}":ro "${IMAGE}" "$@"
}
check() { # name expected actual
  if [ "$2" == "$3" ]; then echo "PASS: $1"; else echo "FAIL: $1"; echo "  expected: [$2]"; echo "  actual:   [$3]"; FAILED=1; fi
}

cat > "${WORKDIR}/vars.j2" <<'TPL'
host={{ DEPLOYMENT_EXT_HOST }}
TPL
check "environment variables are the context" "host=acceptance.example.org" \
  "$(render -e DEPLOYMENT_EXT_HOST=acceptance.example.org -- "${WORKDIR}/vars.j2")"

cat > "${WORKDIR}/cond.j2" <<'TPL'
{% if FEATURE_ENABLED == "true" %}on{% else %}off{% endif %}
TPL
check "condition (true)" "on" "$(render -e FEATURE_ENABLED=true -- "${WORKDIR}/cond.j2")"
check "condition (false)" "off" "$(render -e FEATURE_ENABLED=false -- "${WORKDIR}/cond.j2")"
check "condition (unset, --undefined)" "off" "$(render -- --undefined "${WORKDIR}/cond.j2")"

cat > "${WORKDIR}/undef.j2" <<'TPL'
[{{ NOT_DEFINED }}]
TPL
check "undefined variable is empty with --undefined" "[]" "$(render -- --undefined "${WORKDIR}/undef.j2")"
if render -- "${WORKDIR}/undef.j2" &>/dev/null; then
  echo "FAIL: undefined variable must be an error without --undefined"; FAILED=1
else
  echo "PASS: undefined variable is an error without --undefined"
fi

cat > "${WORKDIR}/filters.j2" <<'TPL'
{{ MODE | default("SAML", true) }} {{ VERSION | int(10) + 1 }} {{ NAME | upper }}
TPL
check "filters (default on empty, int, upper)" "SAML 11 EXO" \
  "$(render -e MODE= -e VERSION=10 -e NAME=exo -- "${WORKDIR}/filters.j2")"

printf 'a={{ A }}\n\nb={{ A }}\n' > "${WORKDIR}/newline.j2"
check "trailing newline and blank lines are kept" "$(printf 'a=1\n\nb=1\n' | od -c)" \
  "$(render -e A=1 -- "${WORKDIR}/newline.j2" | od -c)"

STDERR="$(render -e A=1 -- "${WORKDIR}/newline.j2" 2>&1 >/dev/null)"
check "nothing on stderr (no version banner)" "" "${STDERR}"

if [ "${FAILED}" -ne 0 ]; then echo "Some tests failed"; exit 1; fi
echo "All tests passed"
