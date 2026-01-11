clangd-conf-create() {
    local args
    args=$(getopt -a -o e --long esp32 -- "$@")
    if [[ "$?" != "0" ]]; then
        echo "Usage : clangd-conf-create [-e | --esp32]"
        return 1
    fi

    local ESP32=0

    eval set -- ${args}
    while :
    do
        case $1 in
            -e | --esp32) ESP32=1; shift ;;
            --) shift; break;;
            *) echo "Unsupported option $1. Usage : clangd-conf-create [-e | --esp32]"; 
        esac
    done

    if [[ "$ESP32" == "1" ]]; then
        cp -i ~/.bashrc-scripts/templates/.clangd-esp32 ./.clangd
    else
        cp -i ~/.bashrc-scripts/templates/.clangd-standard ./.clangd
    fi

    if [[ "$?" == "0" ]]; then 
        clangd-conf-make
    fi
}

clangd-conf-make() {
    sed -i "s@\${pwd}@$(pwd)@" .clangd
}
