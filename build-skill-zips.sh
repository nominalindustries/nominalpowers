#!/usr/bin/env bash
#
# build-skill-zips.sh
#
# Packages each skill in skills/ as its own zip in build/, one skill per zip.
# Chat-mode skill upload in claude.ai takes a single-skill zip at a time, so
# this produces one uploadable archive per skill. The Cowork/Code path uses
# the marketplace instead and does not need these.
#
# Each zip contains the skill folder at its root, e.g. build/sbtb.zip holds
# sbtb/SKILL.md, which is the layout the uploader expects.
#
# Usage:  ./build-skill-zips.sh
# Output: build/<skill-name>.zip for every folder in skills/
# Note:   build/ is gitignored, it is a generated artifact.

set -euo pipefail

# Resolve the repo root as the directory this script lives in, so it works
# regardless of where it is called from.
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="${REPO_ROOT}/skills"
BUILD_DIR="${REPO_ROOT}/build"

if [[ ! -d "${SKILLS_DIR}" ]]; then
  echo "error: no skills/ directory found at ${SKILLS_DIR}" >&2
  exit 1
fi

# Start from a clean build dir so deleted skills do not leave stale zips behind.
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

count=0
for skill_path in "${SKILLS_DIR}"/*/; do
  # Guard against the glob matching nothing.
  [[ -d "${skill_path}" ]] || continue

  skill_name="$(basename "${skill_path}")"

  if [[ ! -f "${skill_path}/SKILL.md" ]]; then
    echo "warning: skipping ${skill_name}, no SKILL.md found" >&2
    continue
  fi

  # Zip from inside skills/ so the archive contains <skill-name>/... at its root.
  ( cd "${SKILLS_DIR}" && zip -rq "${BUILD_DIR}/${skill_name}.zip" "${skill_name}" -x '*.DS_Store' )
  echo "built  build/${skill_name}.zip"
  count=$((count + 1))
done

echo ""
echo "done: ${count} skill zip(s) in build/"
