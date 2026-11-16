_esp_activate() {
    if ! [ -n "$BASH_SETUP_ESP_IDF_DIR" ]; then
        return
    fi

    local EXPORT_SCRIPT="$BASH_SETUP_ESP_IDF_DIR/export.sh"

    if ! [ -f "$EXPORT_SCRIPT" ]; then 
        echo "Variable \$BASH_SETUP_ESP_IDF_DIR is set but $EXPORT_SCRIPT do not exist. Please fix your installation or diable esp-idf setup" >&2 
        return 1
    fi

    _BASH_SETUP_ESP_IS_SETUP="FALSE"
    _esp_setup() {
        if [ "$_BASH_SETUP_ESP_IS_SETUP" != "FALSE" ]; then
            return 0
        fi

        source "$BASH_SETUP_ESP_IDF_DIR/export.sh"
        export _BASH_SETUP_ESP_IS_SETUP="TRUE"
    }

    idf.py() {
        _esp_setup && command idf.py "$@"
    }

    alias idf_all="idf.py build && idf.py flash && idf.py monitor"
}

_esp_activate
