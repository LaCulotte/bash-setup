# Copyright (c) 2010, Huy Nguyen, http://www.huyng.com
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without modification, are permitted provided 
# that the following conditions are met:
# 
#     * Redistributions of source code must retain the above copyright notice, this list of conditions 
#       and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the
#       following disclaimer in the documentation and/or other materials provided with the distribution.
#     * Neither the name of Huy Nguyen nor the names of contributors
#       may be used to endorse or promote products derived from this software without 
#       specific prior written permission.
#       
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED 
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
# PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR 
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
# TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING 
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE.


# USAGE: 
# s bookmarkname - saves the curr dir as bookmarkname
# g bookmarkname - jumps to the that bookmark
# g b[TAB] - tab completion is available
# p bookmarkname - prints the bookmark
# p b[TAB] - tab completion is available
# d bookmarkname - deletes the bookmark
# d [TAB] - tab completion is available
# l - list all bookmarks

# setup file to store bookmarks
if [ ! -n "$SDIRS" ]; then
    SDIRS=~/.sdirs
fi
touch $SDIRS

RED="0;31m"
GREEN="0;33m"

# save current directory to bookmarks
function _bookmark_save {
    _bookmark_check_help $1
    _bookmark_name_valid "$@"
    if [ -z "$exit_message" ]; then
        _purge_line "$SDIRS" "export DIR_$1="
        CURDIR=$(echo $PWD| sed "s#^$HOME#\$HOME#g")
        echo "export DIR_$1=\"$CURDIR\"" >> $SDIRS
    fi
}

function _bookmark_select() {
    if [ "$(type -t menu_selector)" != "function" ]; then 
        return 1
    fi    

    source $SDIRS

    local count=0
    local init_count=0
    local list="$(env | sort | grep DIR_)"
    local prompts=( )
    while IFS= read -r line; do
        local bm="$(echo $line | sed 's/DIR_//' | sed 's/=.*//' )"

        if [ "$bm" == "$_CURR_BOOKMARK" ]; then 
            init_count=$count
        fi

        prompts+=( "$bm" )
        count=$(expr $count + 1)
    done <<< "$list"

    menu_selector -r -i $init_count -L ${#prompts[@]} "${prompts[@]}"
    if [[ "$?" != "0" ]]; then 
        return 1
    fi

    __BOOKMARK_DEST="${prompts[$__MENU_SELECTOR_POS]}"
}

# jump to bookmark
function _bookmark_go {
    _bookmark_check_help $1
    source $SDIRS

    local bm=$1
    if [ "$1" == "" ]; then 
        local __BOOKMARK_DEST=""
        _bookmark_select
        if [[ "$?" != "0" ]]; then
            return 1
        fi
        bm="$__BOOKMARK_DEST"
    fi

    target="$(eval $(echo echo $(echo \$DIR_$bm)))"
    if [ -d "$target" ]; then
        cd "$target"
    elif [ ! -n "$target" ]; then
        echo -e "\033[${RED}WARNING: '${bm}' bashmark does not exist\033[00m"
    else
        echo -e "\033[${RED}WARNING: '${target}' does not exist\033[00m"
    fi
}

function _bookmark_go_build {
    _bookmark_check_help $1
    source $SDIRS

    local bm=$1
    if [ "$1" == "" ]; then 
        local __BOOKMARK_DEST=""
        _bookmark_select
        if [[ "$?" != "0" ]]; then
            return 1
        fi
        bm="$__BOOKMARK_DEST"
    fi

    target="$(eval $(echo echo $(echo \$DIR_$bm)))"
    if [ -d "$target/build" ]; then
        cd "$target/build"
    elif [ -d "$target" ]; then
        cd "$target"
    elif [ ! -n "$target" ]; then
        echo -e "\033[${RED}WARNING: '${bm}' bashmark does not exist\033[00m"
    else
        echo -e "\033[${RED}WARNING: '${target}' does not exist\033[00m"
    fi
}

# print bookmark
function _bookmark_print {
    _bookmark_check_help $1
    source $SDIRS
    echo "$(eval $(echo echo $(echo \$DIR_$1)))"
}
 
# delete bookmark
function _bookmark_delete {
    _bookmark_check_help $1
    _bookmark_name_valid "$@"
    if [ -z "$exit_message" ]; then
        _purge_line "$SDIRS" "export DIR_$1="
        unset "DIR_$1"
    fi
}

function _bookmark_help {
    echo ''
    echo 's <bookmark_name> - Saves the current directory as "bookmark_name"'
    echo 'g <bookmark_name> - Goes (cd) to the directory associated with "bookmark_name"'
    echo 'gb <bookmark_name> - Goes (cd) to the directory associated with "bookmark_name"'
    echo 'p <bookmark_name> - Prints the directory associated with "bookmark_name"'
    echo 'd <bookmark_name> - Deletes the bookmark'
    echo 'l                 - Lists all available bookmarks'
    kill -SIGINT $$
}

# print out help for the forgetful
function _bookmark_check_help {
    if [ "$1" = "-h" ] || [ "$1" = "-help" ] || [ "$1" = "--help" ] ; then
        _bookmark_help
    fi
}

# list bookmarks with dirnam
function _bookmark_list {
    _bookmark_check_help $1
    source $SDIRS
        
    # if color output is not working for you, comment out the line below '\033[1;32m' == "red"
    env | sort | awk '/^DIR_.+/{split(substr($0,5),parts,"="); printf("\033[0;33m%-20s\033[0m %s\n", parts[1], parts[2]);}'
    
    # uncomment this line if color output is not working with the line above
    # env | grep "^DIR_" | cut -c5- | sort |grep "^.*=" 
}
# list bookmarks without dirname
function _l {
    source $SDIRS
    env | grep "^DIR_" | cut -c5- | sort | grep "^.*=" | cut -f1 -d "=" 
}

# validate bookmark name
function _bookmark_name_valid {
    exit_message=""
    if [ -z $1 ]; then
        exit_message="bookmark name required"
        echo $exit_message
    elif [ "$1" != "$(echo $1 | sed 's/[^A-Za-z0-9_]//g')" ]; then
        exit_message="bookmark name is not valid"
        echo $exit_message
    fi
}

# completion command
function _bookmark_complete {
    local curw
    COMPREPLY=()

    curw=${COMP_WORDS[COMP_CWORD]}

    if [[ "$COMP_CWORD" == "1" ]]; then
        local list=( s g gb p d l )
        COMPREPLY=($(compgen -W "${list[*]}" -- $curw))
        # COMPREPLY=( s g p d l )
    elif [[ "$COMP_CWORD" == "2" && "${COMP_WORDS[1]}" != "s" ]]; then 
        # COMPREPLY=($(compgen -W '`_l`' -- $curw))
        _bookmark_complete_file
    fi

    return 0
}

function _bookmark_complete_file {
    curw=${COMP_WORDS[COMP_CWORD]}
    COMPREPLY=($(compgen -W '`_l`' -- $curw))

    return 0
}

# ZSH completion command
function _bookmark_completezsh {
    reply=($(_l))
}

# safe delete line from sdirs
function _purge_line {
    if [ -s "$1" ]; then
        # safely create a temp file
        t=$(mktemp -t bashmarks.XXXXXX) || exit 1
        trap "/bin/rm -f -- '$t'" EXIT

        # purge line
        sed "/$2/d" "$1" > "$t"
        /bin/mv "$t" "$1"

        # cleanup temp file
        /bin/rm -f -- "$t"
        trap - EXIT
    fi
}

function bookmark {
    _bookmark_check_help $1
    local args=($@)
    unset 'args[0]'

    case $1 in
        s)
            _bookmark_save "${args[*]}"
            ;;
        d)
            _bookmark_delete "${args[*]}"
            ;;
        g)
            _bookmark_go "${args[*]}"
            ;;
        gb)
            _bookmark_go_build "${args[*]}"
            ;;
        l)
            _bookmark_list "${args[*]}"
            ;;
        p)
            _bookmark_print "${args[*]}"
            ;;
        *)
            _bookmark_help
            ;;
    esac
}

# bind completion command for g,p,d to _bookmark_complete
if [ $ZSH_VERSION ]; then
    compctl -K _bookmark_completezsh g
    compctl -K _bookmark_completezsh p
    compctl -K _bookmark_completezsh d
else
    complete -F _bookmark_complete bookmark
fi


# PS1 utils
_CURR_BOOKMARK=""
_CURR_BOOKMARK_PS1=""
_check_curr_bookmark() {
    _CURR_BOOKMARK=""
    _CURR_BOOKMARK_PS1=""
    _CURR_BOOKMARK_PROMPT_PS1=""

    local curr_bm_len="0"
    local curr_line=""
    local pwd=$(pwd | sed -e 's;'"$HOME"';$HOME;')

    while IFS= read -r line; do
        if [[ (( ${#line} > $curr_bm_len )) ]] && [[ "$pwd" =~ "$line".* ]]; then
            curr_bm_len="${#line}"
            curr_line=$line
        fi
    done <<< "$(sed -e 's/.*DIR_//' $SDIRS | cut -d'"' -f2)"

    if [[ "$curr_line" != "" ]]; then
        _CURR_BOOKMARK="$(sed -e 's/.*DIR_//' $SDIRS | grep $curr_line\" | cut -d"=" -f1)"
        _CURR_BOOKMARK_PS1="$_CURR_BOOKMARK"
        _CURR_BOOKMARK_PROMPT_PS1=" - "
    fi
}
