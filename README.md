# Package repositories for Jamulus

This repository creates the Debian repository for Jamulus. Please find more information and the `.deb` files on the GitHub release tab.

## Debian

Install this `.deb` repo on your Ubuntu/Debian system with the following command:

```
curl -sL https://github.com/jamulussoftware/repos/releases/download/deb-release/setup.sh | bash
```

## Internal setup for hosting a Debian repository on GitHub

Endusers who just want to install Jamulus via apt **do not** need to read this section. This is just documentation for development.

### Setting up secrets

To setup the hosting, you first need to generate a gpg key on your local machine:

```
gpg --homedir gpghome --gen-key
```

Afterwards, all work can be done via GitHubs' web interface:

* Export the GPG key and copy and paste the private key as GitHub secret with the name "GPG_PRIVATE_KEY" in your Repos' settings
* In the Actions tab, run the "Create or update repo workflow".
* Now run the "Import latest packages" workflow

### Steps for updating packages

This is section is work in progress.

### Related links and notes for development

https://wiki.debian.org/DebianRepository/SetupWithReprepro

reprepro includedeb focal /repos/*.deb
