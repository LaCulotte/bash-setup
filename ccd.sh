ccd() {
    local curr=$(pwd)
    builtin cd "$@"

    if [ "$?" == "0" ] && [ "$(pwd)" != "$curr" ]; then
        if (( $CCD_SIZE == 0 )); then 
            CCD_HISTORY[0]=$curr
            CCD_POINTER=1
        fi

        local OLD_CCD_POINTER=$CCD_POINTER

        CCD_HISTORY[CCD_POINTER]=$(pwd)
        CCD_POINTER=$(expr $(expr $CCD_POINTER + 1) % $CCD_MAX)

        if (( $CCD_TAIL == $OLD_CCD_POINTER )); then
            CCD_TAIL=$CCD_POINTER
        fi

        CCD_HEAD=$CCD_POINTER
        CCD_SIZE=${#CCD_HISTORY[@]}
    fi
}

ccd_show() {
    if (( $CCD_SIZE == 0 )); then
        echo "Empty stack"
        return 1
    fi
    
    local i=$(expr $CCD_TAIL % $CCD_SIZE)
    local k=0
    local stop=0
    local current=$(expr $CCD_POINTER - 1)

    if (( $current < 0 )); then 
        current=$(expr $current + $CCD_SIZE)
    fi

    while [[ "$stop" == "0" ]]; do
        local prompt="$k - ${CCD_HISTORY[i]}"

        if [[ "$i" == "$current" ]]; then
            prompt="\033[1;31m$prompt <"
        fi

        i=$(expr $(expr $i + 1) % $CCD_SIZE)
        k=$(expr $(expr $k + 1) % $CCD_SIZE)

        printf "$prompt\n\033[0m"

        if [[ $i == $(expr $CCD_HEAD % $CCD_SIZE) ]]; then 
            stop=1
        fi
    done
}

ucd() {
    if (( $CCD_SIZE == 0 )); then
        echo "Empty stack"
        return 1
    fi
    
    local NEW_CCD_POINTER=$(expr $CCD_POINTER - 1)

    if (( $NEW_CCD_POINTER < 0 )); then 
        NEW_CCD_POINTER=$(expr $NEW_CCD_POINTER + $CCD_SIZE)
    fi

    if (( $NEW_CCD_POINTER == $CCD_TAIL )); then 
        echo "End of stack"
        return 1
    fi

    CCD_POINTER=$NEW_CCD_POINTER

    local ptr=$(expr $CCD_POINTER - 1)
    if (( $ptr < 0 )); then
        ptr=$(expr $ptr + $CCD_SIZE)
    fi

    builtin cd ${CCD_HISTORY[ptr]}
}

rcd() {
    if (( $CCD_SIZE == 0 )); then
        echo "Empty stack"
        return 1
    fi

    if (( $CCD_POINTER == $CCD_HEAD )); then 
        echo "End of stack"
        return 
    fi

    builtin cd ${CCD_HISTORY[CCD_POINTER]}

    CCD_POINTER=$(expr  $(expr $CCD_POINTER + 1) % $CCD_MAX)
}

ccgo() {
    if (( $CCD_SIZE == 0 )); then
        echo "Empty stack"
        return 1
    fi

    local i=$(expr $CCD_TAIL % $CCD_SIZE)
    local k=0
    local stop=0
    local current=$(expr $CCD_POINTER - 1)

    if (( $current < 0 )); then 
        current=$(expr $current + $CCD_SIZE)
    fi

    local arr=( )
    while [[ "$stop" == "0" ]]; do
        local prompt="$k - ${CCD_HISTORY[i]}"

        if [[ "$i" == "$current" ]]; then
            prompt="\033[1;31m$prompt <"
            __INPUT_HELPER_POS=$k
        fi
        prompt="$prompt\033[0m"

        i=$(expr $(expr $i + 1) % $CCD_SIZE)
        k=$(expr $(expr $k + 1) % $CCD_SIZE)

        # printf "$prompt\n\033[0m"
        arr+=( "$prompt" )

        if [[ $i == $(expr $CCD_HEAD % $CCD_SIZE) ]]; then 
            stop=1
        fi
    done

    local size=${#arr[@]}
    if [[ "$size" -gt "$(tput lines)" ]]; then 
        size=$(tput lines)
    fi

    menu_selector -r -i $current -L $size "${arr[@]}"

    if [[ "$?" == "0" ]]; then
        local DST=$(expr $(expr $__MENU_SELECTOR_POS + $CCD_TAIL) % $CCD_MAX)

        builtin cd ${CCD_HISTORY[$DST]}
        CCD_POINTER=$(expr $(expr $DST + 1) % $(expr $CCD_SIZE + 1))
    fi
}

export CCD_HISTORY=( )

export CCD_TAIL=0
export CCD_HEAD=0

export CCD_SIZE=0
export CCD_POINTER=0
export CCD_MAX=20