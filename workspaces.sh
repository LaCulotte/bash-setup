WORKSPACE_EDITOR="nvim"

workspace-add() {
    if [[ "$#" != 2 ]]; then 
        echo "Usage : workspace-add <name> <dirs...>"
        return 1;
    fi

    local name=$1
    local dir=$2

    local path=""
    path=$(realpath $2)

    if [[ "$?" != "0" ]]; then 
        echo Error on realpath of $2
        return 1
    fi

    if [[ ! -e $path ]]; then
        echo Path $2 does not exist !
        return 1
    fi

    local root="$(realpath ~/.workspaces/)/"
    local workspace=~/.workspaces/$1
    if [[ "$(echo $(realpath -m $workspace) | grep -e ^$root)" == "" ]]; then 
        echo "$1 Is not a valid workspace (outside of base directory)"
        return 1
    fi

    if [[ ! -e $workspace ]]; then
        echo New workspace $workspace
        mkdir -p $workspace

        if [[ "$?" != "0" ]]; then
            echo "Could not create workspace $1"
            return 1
        fi
    fi

    ln -s $path $workspace
}

workspace-list() {
    if [[ "$#" != 1 ]]; then 
        echo "Usage : workspace-list <name>"
        return 1;
    fi

    local root="$(realpath ~/.workspaces/)/"
    local workspace=~/.workspaces/$1
    if [[ "$(echo $(realpath -m $workspace) | grep -e ^$root)" == "" ]]; then 
        echo "$1 Is not a valid workspace (outside of base directory)"
        return 1
    fi

    if [[ ! -e $workspace ]]; then
        echo "No workspace named $1"
        return 1
    fi

    ls -l $workspace
}



workspace-open() {
    if [[ "$#" != 1 ]]; then 
        echo "Usage : workspace-open <name>"
        return 1;
    fi

    local root="$(realpath ~/.workspaces/)/"
    local workspace=~/.workspaces/$1
    if [[ "$(echo $(realpath -m $workspace) | grep -e ^$root)" == "" ]]; then 
        echo "$1 Is not a valid workspace (outside of base directory)"
        return 1
    fi

    if [[ ! -e $workspace ]]; then
        echo "No workspace named $1"
        return 1
    fi

    nvim -c ":tcd $workspace"
}

workspace-remove() {
    if [[ "$#" != 2 ]]; then 
        echo "Usage : workspace-remove <name> <dir>"
        return 1;
    fi

    local name=$1
    local dir=$2

    local root="$(realpath ~/.workspaces/)/"
    local workspace=~/.workspaces/$1
    if [[ "$(echo $(realpath -m $workspace) | grep -e ^$root)" == "" ]]; then 
        echo "$1 Is not a valid workspace (outside of base directory)"
        return 1
    fi

    if [[ ! -e $workspace ]]; then
        echo "No workspace named $1"
        return 1
    fi

    local path=$workspace/$dir
    if [[ ! -L $path ]]; then
        echo "No dir $2 in workspace $1"
        return 1
    fi

    rm -i $path
}

workspace-delete() {
    if [[ "$(type -t confirm)" != function ]]; then
        echo "Could not find function 'confirm'. Please source framework before executing this"
        return 1
    fi

    if [[ "$#" != 1 ]]; then 
        echo "Usage : workspace-delete <name>"
        return 1;
    fi

    local root="$(realpath ~/.workspaces/)/"
    local workspace=~/.workspaces/$1
    if [[ "$(echo $(realpath -m $workspace) | grep -e ^$root)" == "" ]]; then 
        echo "$1 Is not a valid workspace (outside of base directory)"
        return 1
    fi

    if [[ ! -e $workspace ]]; then
        echo "No workspace named $1"
        return 1
    fi

    confirm "$(echo -e "Are you sure you want to DELETE \e[1;31m$workspace\e[0m ? (y/N)")"
    if [[ "$?" == "0" ]]; then
        rm -rf $workspace
        echo "Deleted $workspace"
    else 
        echo "Abort"
    fi
}

__workspace_complete_one() {
    COMPREPLY=()
    if [[ "$COMP_CWORD" == "1" ]]; then
        __workspace_complete_name
    fi
}

__workspace_complete_remove() {
    COMPREPLY=()
    if [[ "$COMP_CWORD" == "1" ]]; then
        __workspace_complete_name
    elif [[ "$COMP_CWORD" == "2" ]]; then
        __workspace_complete_dir ${COMP_WORDS[1]}
    fi
}

__workspace_complete_add() {
    COMPREPLY=()
    if [[ "$COMP_CWORD" == "1" ]]; then
        __workspace_complete_name
    elif [[ "$COMP_CWORD" == "2" ]]; then
        local curw=${COMP_WORDS[COMP_CWORD]}
        COMPREPLY=($(compgen -d $curw))
        return 0
    fi
}

__workspace_complete_name() {
    local curw
    COMPREPLY=()

    curw=${COMP_WORDS[COMP_CWORD]}
    COMPREPLY=($(compgen -W "$(ls ~/.workspaces)" -- $curw))

    return 0
}

__workspace_complete_dir() {
    local curw
    COMPREPLY=()

    local curr_workspace=~/.workspaces/$1
    if [[ ! -e $curr_workspace ]]; then
        return 1
    fi

    curw=${COMP_WORDS[COMP_CWORD]}
    COMPREPLY=($(compgen -W "$(ls $curr_workspace)" -- $curw))

    return 0
}

complete -F __workspace_complete_one workspace-open
complete -F __workspace_complete_one workspace-list
complete -F __workspace_complete_one workspace-delete
complete -F __workspace_complete_remove workspace-remove
complete -F __workspace_complete_add workspace-add
