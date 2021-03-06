#!/usr/bin/env sh

set -e

CLR_SUCCESS="\033[1;32m"    # BRIGHT GREEN
CLR_CLEAR="\033[0m"         # DEFAULT COLOR
ECHO='echo'

AM_HOME="$HOME/.am"
AM_PROMPT="$AM_HOME/prompt"

# when not outputing to a tty, add spacing instead of colors
if [ ! -t 1 ]; then
    CLR_SUCCESS="\n------------------------------------------------------------------------------------------------------------------------\n"
    CLR_CLEAR=$CLR_SUCCESS
    ECHO='printf'
fi

__am_prompt_success() {
    $ECHO "${CLR_SUCCESS}prompt-install: $1${CLR_CLEAR}"
}

__am_prompt_install() {
    local NOW=$(date +"%Y%m%d_%H%M%S")
    local BACKUP_PATH="$AM_HOME/backup/prompt/$NOW"

    __am_prompt_success "creating backup path: $BACKUP_PATH"
    mkdir -p "$BACKUP_PATH" 1>/dev/null

    for TEMPLATE in template/*; do
        local TEMPLATE_NAME=$(basename "$TEMPLATE")
        local TEMPLATE_PATH="$HOME/.${TEMPLATE_NAME}"

        if [ -f "$TEMPLATE_PATH" ]; then
            __am_prompt_success "backing up ${TEMPLATE_NAME}"
            cp "$TEMPLATE_PATH" "$BACKUP_PATH/$TEMPLATE_NAME"
        fi

        cp "$TEMPLATE" "$TEMPLATE_PATH"
    done

    if [ -d $AM_PROMPT ]; then
        __am_prompt_success "backing up $AM_PROMPT"
        cp -R $AM_PROMPT/* "$BACKUP_PATH" 1>/dev/null

        __am_prompt_success "removing $AM_PROMPT"
        rm -rf "$AM_PROMPT/bash" 1>/dev/null 2>&1
        rm -rf "$AM_PROMPT/sh" 1>/dev/null 2>&1
        rm -rf "$AM_PROMPT/zsh" 1>/dev/null 2>&1
        rm -rf "$AM_PROMPT/themes" 1>/dev/null 2>&1

        # remove legacy paths
        rm -rf "$AM_PROMPT/completions" 1>/dev/null 2>&1
        rm -rf "$AM_PROMPT/scripts" 1>/dev/null 2>&1
        rm -f "$AM_PROMPT/bashrc" 1>/dev/null 2>&1
    fi

    __am_prompt_success "creating $AM_PROMPT"
    mkdir -p "$AM_PROMPT/user" 1>/dev/null 2>&1

    __am_prompt_success "installing promptMastermind to $AM_PROMPT"
    cp -Rf src/bash "$AM_PROMPT" 1>/dev/null
    cp -Rf src/sh "$AM_PROMPT" 1>/dev/null
    cp -Rf src/zsh "$AM_PROMPT" 1>/dev/null
    cp -Rf src/themes "$AM_PROMPT" 1>/dev/null

    for USER_ITEM in src/user/*; do
        local USER_ITEM_NAME=$(basename "$USER_ITEM")
        local USER_ITEM_PATH="$AM_PROMPT/user/$USER_ITEM_NAME"

        if [ ! -f "$USER_ITEM_PATH" ]; then
            __am_prompt_success "initializing user profile: $USER_ITEM_NAME at $USER_ITEM_PATH"
            cp "$USER_ITEM" "$USER_ITEM_PATH"
        fi
    done

    local UNAME=$(uname | tr '[:upper:]' '[:lower:]')
    local UNAME_INSTALL="$UNAME.sh"

    if [ -f /etc/os-release ]; then
        . /etc/os-release

        local UNAME_INSTALL="$ID.sh"
    fi

    if [ -f "$AM_PROMPT/sh/install/$UNAME_INSTALL" ]; then
        . "$AM_PROMPT/sh/install/$UNAME_INSTALL"
    fi

    if [ ! -d "$AM_PROMPT/zsh/completions" ]; then
        mkdir -p "$AM_PROMPT/zsh/completions" 1>/dev/null
    fi

    if [ ! -d "$AM_PROMPT/bash/completions" ]; then
        mkdir -p "$AM_PROMPT/bash/completions" 1>/dev/null
    fi

    local GIT_PROMPT_NAME=git-prompt.sh
    local GIT_PROMPT_URI=https://raw.githubusercontent.com/lyze/posh-git-sh/master/$GIT_PROMPT_NAME

    __am_prompt_success 'downloading better git-prompt'
    local CURL_RESULT=$(curl -sLD- "$GIT_PROMPT_URI" -o "$AM_PROMPT/zsh/completions/_git-prompt" -# | grep "^HTTP/1.1" | head -n 1 | sed "s/HTTP.1.1 \([0-9]*\).*/\1/")

    if [ "$CURL_RESULT" = "200" ]; then
        __am_prompt_success 'successfully installed git-prompt'
        chmod +x "$AM_PROMPT/zsh/completions/_git-prompt" 1>/dev/null

        # copy for consumption in bash as well
        cp "$AM_PROMPT/zsh/completions/_git-prompt" "$AM_PROMPT/bash/completions/git-prompt.sh"
    fi

    local CURL_OPT='-s'

    if [ ! -z "${GH_TOKEN:-}" ]; then
        local CURL_OPT="$CURL_OPT -H 'Authorization: token $GH_TOKEN'"
    fi

    local SHA_URI="https://api.github.com/repos/automotivemastermind/prompt/commits/master"
    local PROMPT_SHA=$(curl $CURL_OPT $SHA_URI | grep sha | head -n 1 | sed 's#.*\:.*"\(.*\).*",#\1#')
    local PROMPT_SHA_PATH=$HOME/.am/prompt/.sha
    local PROMPT_CHANGELOG_URI="https://github.com/automotivemastermind/prompt/blob/$PROMPT_SHA/CHANGELOG.md"

    echo $PROMPT_SHA > $PROMPT_SHA_PATH

    # get the requested shell
    local PROMPT_SHELL="${1:-}"

    # determine if the request shell was not set
    if [ -z "${PROMPT_SHELL:-}" ]; then

        # get the current shell
        PROMPT_SHELL=$(echo $SHELL | rev | cut -d'/' -f1 | rev)

        # test if the current shell is something other than zsh
        if [ "$PROMPT_SHELL" != "zsh" ]; then

            # default to bash
            PROMPT_SHELL="bash"
        fi
    fi

    # lowercase the prompt shell
    local PROMPT_SHELL=$(echo $PROMPT_SHELL | tr '[:upper:]' '[:lower:]')

    # use the correct shell
    . $AM_PROMPT/sh/scripts/use-shell $PROMPT_SHELL

    # open the changelog url
    . $AM_PROMPT/sh/scripts/open-url $PROMPT_CHANGELOG_URI 1>/dev/null
}

__am_prompt_install $@
