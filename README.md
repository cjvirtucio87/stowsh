# stowsh

## Overview
A linux command for setting up your local development environment. It clones your dotfiles project, deploys them to your `$DOTFILES_DEPLOY_DIR` (e.g. `/mnt/c/Users/foo`), and creates symbolic links that point to these dotfiles in your `$HOME` folder.

You can also update your dotfiles project by running `stowsh update`, copying your dotfiles back into the cloned dotfiles repo. It also ignores certain folders based on the contents of your dotfiles repo's `.gitignore` file.

There is also a pass-thru to the `git` command to manage your dotfiles repo, e.g. `stowsh git status` to view the status of your dotfiles repo.

## Caveats

Currently only supports `Ubuntu 18.04 (Bionic Beaver)`.

## Setup

Download one of the [releases](stowsh/releases).

Unarchive to wherever, e.g. `/opt/stowsh-0.1.0`.

Make sure the required environment variables are setup correctly; specifically:

* `$PATH` must be set to `/your/stowsh/install/bin:${PATH}`
* `$HOME` must point to your home directory.
* `$DOTFILES_URL` must point to your remote repo.
* `$DOTFILES_PLATFORM` must point to your desired platform _within_ your dotfiles repo.
* `$DOTFILES_DEPLOY_DIR` must point to where you want your dotfiles to be deployed.

The script has defaults that could possibly serve as examples. They're currently setup to run on my machine (`Ubuntu 18.04` on `WSL`).

## Usage
See the help message for more information:

```
stowsh -h
```

