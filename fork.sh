#!/bin/bash

set -e

git config --global credential.helper store
git config --global user.name "HotelMoted"
git config --global user.email "HotelMoted@peter.lol"

SCRIPT_DIR="$( cd "$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )" &> /dev/null && pwd )"
REPO_DIR="$SCRIPT_DIR"
REMOTE_FORK="origin"
REMOTE_UPSTREAM="upstream"
BRANCH_NAME="master"
UPSTREAM_URL="https://github.com/ipxe/ipxe.git"
BUILD_SUFFIX="hotelmoted"

cd "$REPO_DIR"
git checkout "$BRANCH_NAME"

if ! git remote get-url "$REMOTE_UPSTREAM" > /dev/null 2>&1; then
    git remote add "$REMOTE_UPSTREAM" "$UPSTREAM_URL"
else
    git remote set-url "$REMOTE_UPSTREAM" "$UPSTREAM_URL"
fi

STASH_APPLIED=false
# Check for unstaged or staged changes before rebase
if ! git diff-index --quiet HEAD -- || ! git diff-index --quiet --cached HEAD --; then
  git stash push -m "fork.sh stash $(date)"
  STASH_APPLIED=true
fi

git fetch "$REMOTE_UPSTREAM" --tags
# --- Rebase might pause here for conflict resolution ---
git rebase "${REMOTE_UPSTREAM}/${BRANCH_NAME}"
# --- Script resumes after user resolves conflicts (if any) and runs 'git rebase --continue' ---

if [ "$STASH_APPLIED" = true ] ; then
    STASH_REF=$(git stash list -n 1 | grep "fork.sh stash" | cut -d: -f1)
    if [ -n "$STASH_REF" ]; then
        if ! git stash pop "$STASH_REF"; then
            # Keep this error block for user guidance on conflict
            echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" >&2
            echo "ERROR: Failed to pop stash due to conflicts." >&2
            echo "Please resolve conflicts manually, then stage changes," >&2
            echo "and run 'git commit --amend --reset-author' before running this script again." >&2
            echo "(Or run 'git stash drop $STASH_REF' to discard stashed changes)" >&2
            echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" >&2
            exit 1
        fi
    fi
fi

# Stage ALL current changes (including those popped from stash, if any)
git add .

# Amend the latest commit (which is now the rebased version of user's previous work)
# This assumes 'git add .' above staged something, or we just want to reset author
git commit --amend --reset-author --no-edit

NEW_COMMIT_HASH=$(git rev-parse HEAD)
git push --force-with-lease "$REMOTE_FORK" "$BRANCH_NAME"

REMOTE_TAG_LIST=$(git ls-remote --tags "$REMOTE_FORK" | awk '/\/tags\// {sub("refs/tags/", ""); print $2}')

if [ -n "$REMOTE_TAG_LIST" ]; then
    printf '%s\n' "$REMOTE_TAG_LIST" | while IFS= read -r tag_to_delete; do
        git push "$REMOTE_FORK" --delete "$tag_to_delete" || true
    done
    printf '%s\n' "$REMOTE_TAG_LIST" | while IFS= read -r tag_to_delete; do
         if git rev-parse "$tag_to_delete" >/dev/null 2>&1; then
             git tag -d "$tag_to_delete" || true
         fi
    done
fi

BASE_TAG_VERSION=$(git describe --tags --abbrev=0 "$NEW_COMMIT_HASH" 2>/dev/null || git describe --tags --abbrev=0 "${NEW_COMMIT_HASH}^" 2>/dev/null || echo "v0.0.0")
BUILD_TAG_NAME="${BASE_TAG_VERSION}-${BUILD_SUFFIX}"

git tag "$BUILD_TAG_NAME" "$NEW_COMMIT_HASH"
git push "$REMOTE_FORK" "$BUILD_TAG_NAME"
