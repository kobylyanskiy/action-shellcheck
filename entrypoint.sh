#!/bin/sh

set -o pipefail

cd "${GITHUB_WORKSPACE}" || exit

export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"

if [ "${INPUT_REPORTER}" = 'github-pr-review' ]; then
  # erroformat: https://git.io/JeGMU
  shellcheck -f json  ${INPUT_SHELLCHECK_FLAGS:-'--external-sources'} $(find "${INPUT_PATH:-'.'}" -path "./build/*" -prune -o -path "./meta-layers/*" -prune -o -type f -name "${INPUT_PATTERN:-'*.sh'}" -print) \
    | tee output | jq -r '.[] | "\(.file):\(.line):\(.column):\(.level):\(.message) [SC\(.code)](https://github.com/koalaman/shellcheck/wiki/SC\(.code))"' \
    | reviewdog -efm="%f:%l:%c:%t%*[^:]:%m" -name="shellcheck" -reporter=github-pr-review -level="${INPUT_LEVEL}"; ERR_CODE=$?; cat output; rm output; exit $ERR_CODE
else
  # github-pr-check,github-check (GitHub Check API) doesn't support markdown annotation.
  shellcheck -f checkstyle ${INPUT_SHELLCHECK_FLAGS:-'--external-sources'} $(find "${INPUT_PATH:-'.'}" -not -path "${INPUT_EXCLUDE}" -type f -name "${INPUT_PATTERN:-'*.sh'}") \
    | reviewdog -f="checkstyle" -name="shellcheck" -reporter="${INPUT_REPORTER:-github-pr-check}" -level="${INPUT_LEVEL}"
fi
