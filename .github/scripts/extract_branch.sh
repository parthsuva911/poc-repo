echo "${GITHUB_EVENT_NAME}"
if [[ "${GITHUB_EVENT_NAME}" == "push" ]]; then
    echo "::set-output name=branch::$(echo ${GITHUB_REF##*/})"
elif [[ "${GITHUB_EVENT_NAME}" == "pull_request" ]]; then
    echo "::set-output name=branch::$(echo $GITHUB_BASE_REF)"
else
    echo "::set-output name=branch::INVALID_EVENT_BRANCH_UNKNOWN"
fi