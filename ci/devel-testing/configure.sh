#!/usr/bin/env bash

set -euo pipefail

# credhub set -n /concourse/main/ssh_key_gitlab -t value -v "$(lpass show --notes "id_rsa_gitlab")" > /dev/null
# credhub set -n /concourse/main/gcp_key -t password -w "$(lpass show --notes 'turbo-140')" > /dev/null

repo_root=$(git rev-parse --show-toplevel)
pipeline="turbo-testing"

fly -t env0 sp -p ${pipeline} -c ${repo_root}/ci/devel-testing/pipeline.yml -n
fly -t env0 up -p ${pipeline}
