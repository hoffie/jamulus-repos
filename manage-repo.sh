set -eu

FORMAT="deb"
NAME="${FORMAT}-${CHANNEL}"
TITLE="Jamulus Repo for Debian/Ubuntu (${CHANNEL})"
GENERATOR_ROOT="${PWD}"
TMP_ROOT="${PWD}/tmp/"

GPGHOME="${TMP_ROOT}/gpghome"
GPG_PUBKEY_FILE="key.asc"
SETUP_SH="setup.sh"
REPO="${TMP_ROOT}/repo"

mkdir -p "$REPO"

setup_gpg() {
    [[ "${GPG_PRIVATE_KEY:-}" ]] || {
        echo "Missing Github secret GPG_PRIVATE_KEY"
        exit 1
    }
    mkdir -p "$GPGHOME"
    chmod 700 "$GPGHOME"

    echo "$GPG_PRIVATE_KEY" | gpg --homedir "$GPGHOME" --import -
}

ensure_github_release() {
    git tag -f "$NAME" HEAD
    git push origin +refs/tags/"$NAME"
    if ! gh release view "$NAME" &>/dev/null; then
        gh release create "$NAME" --notes "(in creation)"
    fi
    NAME="$NAME" SETUP_SH="$SETUP_SH" envsubst '$NAME $GITHUB_REPOSITORY $SETUP_SH' < release-body.md > tmp/release-body.md
    gh release edit "$NAME" --title "$TITLE" --notes-file tmp/release-body.md
}

download_github_release_packages() {
    gh release download "$NAME" --pattern "*.${FORMAT}"
}

generate_and_sign_metadata() {
    apt-ftparchive packages . > Packages
    apt-ftparchive release . > Release
    gpg --homedir "$GPGHOME" --armor --yes --clearsign --output InRelease --detach-sign Release
    gpg --homedir "$GPGHOME" --armor --export > "$GPG_PUBKEY_FILE"

    # Create setup.sh file. Use envsubst to replace repository information in template file 
    NAME="$NAME" GITHUB_REPOSITORY="$GITHUB_REPOSITORY" envsubst '$NAME $GITHUB_REPOSITORY' < "${GENERATOR_ROOT}/setup_base.sh.template" > "${SETUP_SH}"
    
    chmod +x "${SETUP_SH}"
}

replace_github_release_metadata_assets() {
    METADATA_FILES=( Packages Release InRelease "$GPG_PUBKEY_FILE" "$SETUP_SH" )
    for asset in "${METADATA_FILES[@]}"; do
        gh release delete-asset "$NAME" "${asset}" --yes || true
    done
    gh release upload "$NAME" "${METADATA_FILES[@]}"
}

create_repo() {
    setup_gpg
    ensure_github_release
    pushd "$REPO"
    download_github_release_packages
    generate_and_sign_metadata
    replace_github_release_metadata_assets
    popd
}

import_latest_packages() {
    pushd "$REPO"
    gh release download --repo jamulussoftware/jamulus --pattern "*.${FORMAT}"
    gh release upload "$NAME" ./*".${FORMAT}"
}

case "${1:-}" in
    create_repo)
        create_repo
        ;;
    import_latest_packages)
        import_latest_packages
        ;;
    *)
        echo "Unsupported action ${1:-}"
        exit 1
esac
