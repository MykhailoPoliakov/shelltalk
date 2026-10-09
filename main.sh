shopt -s nullglob

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")")"
FOLDER="/tmp/.shelltalk"



if [ -z "$1" ]; then
    echo "No argument given: try write/read" 
    exit 1
fi

case "$1" in
    msg|write) 
        if [ -z "$2" ]; then
            echo "No username entered after the command" 
            exit 1
        fi

        if ! id "$2" >/dev/null 2>&1; then
            echo "User $2 not found"
            exit 1
        fi

        if [ -z "$3" ]; then
            echo "No text entered after the username" 
            exit 1
        fi

         # make a root folder if there is none
        if [[ ! -d "$FOLDER" ]]; then
            mkdir "$FOLDER" 2>/dev/null

            if [[ -d "$FOLDER" ]]; then
                chmod 1777 "$FOLDER"
            else
                echo "Cannot create $FOLDER; it may already exist or permission was denied." >&2
                exit 1
            fi
        fi

        # make a user folder if there is none
        mkdir -p "${FOLDER}/${USER}/${2}"
        chmod 700 "${FOLDER}/${USER}"
        setfacl -m u:${2}:--x "${FOLDER}/${USER}"

        # make a file
        FILE="${FOLDER}/${USER}/${2}/$(date +'%Y-%m-%d_%H-%M-%S-%N').${USER}"

        touch "$FILE"
        chmod 600 "$FILE"
        setfacl -m u:${2}:r "$FILE"

        # write the massage
        echo $3 > $FILE
        exit 0
    ;;

    read)
        if [ -z "$2" ]; then
            echo "No username entered after the command" 
            exit 1
        fi

        if ! id "$2" >/dev/null 2>&1; then
            echo "User $2 not found"
            exit 1
        fi

        if ! [ -z "$3" ]; then
            echo "Extra argument entered: $3" 
            exit 1
        fi


        if [[ ! -d "${FOLDER}/${2}/${USER}"  && ! -d "${FOLDER}/${USER}/${2}" ]]; then 
            echo "No dialog with ${2} was found" 
            exit 1
        fi

        # enter the output
        OTHER_MSGS_DIR="${FOLDER}/${2}/${USER}"
        MY_MSGS_DIR="${FOLDER}/${USER}/${2}"

        cols=$(tput cols)
        echo ""

        # print the chat
        for msg in $(printf '%s\n' "$OTHER_MSGS_DIR"/* "$MY_MSGS_DIR"/* | sort) ; do
            filename=$(basename "$msg")

            username=$(echo "$filename" | cut -d '.' -f 2)

            header="$username $(echo "$filename" | cut -c 1-10) $(echo "$filename" | cut -c 12-19 | tr '-' ':')"
            body="└> $(cat "$msg" 2>/dev/null)"

            if [[ "$username" == "$USER" ]]; then
                printf '%*s\n' "$cols" "$header"
                printf '%*s\n' "$cols" "$body"
            else
                echo "$cols" "$header"
                echo "$cols" "$body"
            fi

            echo ""
        done

    ;;  


    clear)
        if [ -z "$2" ]; then
            echo "No username entered after the command" 
            exit 1
        fi

        if ! id "$2" >/dev/null 2>&1; then
            echo "User $2 not found"
            exit 1
        fi

        if ! [ -d "${FOLDER}/${USER}/${2}" ]; then 
            echo "No dialog with ${USER} was found" 
            exit 1
        fi


        if [[ -n "$FOLDER" && -n "$USER" && -n "$2" && -d "${FOLDER}/${USER}/${2}" ]]; then
            rm -rf -- "${FOLDER}/${USER}/${2}"
            exit 0
        else
            echo "Removal is unsafe"
            exit 1
        fi
    ;;


    *)
        echo "Invalid command"
        exit 1
    ;;
    
esac
