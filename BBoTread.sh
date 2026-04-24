#!/bin/sh
FILE="conversations.json"
model="nvidia/nemotron-nano-12b-v2-vl"
chat_id="0"
recursive=0

# =========================
# PARSING ARGOMENTI
# =========================
while [ $# -gt 0 ]; do
    case "$1" in
        --chat)
            chat_id="$2"
            shift 2
            ;;
        --recursive|-re)
            recursive=1
            shift
            ;;
        --model|-m)
            model="$2"
            shift 2
            ;;
        *)
            prompt="$prompt $1"
            shift
            ;;
    esac
done
prompt=$(echo "$prompt" | sed 's/^ *//')

# =========================
# INIT FILE
# =========================
[ ! -f "$FILE" ] && echo "{}" > "$FILE"

# Escape completo per JSON: gestisce \, ", newline, tab, \r
# Usa awk perchC) sed non gestisce bene input multiriga su busybox/Alpine
# ORDINE CRITICO: prima \ poi gli altri (altrimenti si doppio-escapano)
escape() {
    printf '%s' "$1" | awk '
        BEGIN { ORS="" }
        NR > 1 { printf "\\n" }
        {
            gsub(/\\/, "\\\\")
            gsub(/"/, "\\\"")
            gsub(/\t/, "\\t")
            gsub(/\r/, "\\r")
            printf "%s", $0
        }
    '
}

last_run=""

# =========================
# LOOP (per recursive)
# =========================
while :; do
    prompt_escaped=$(escape "$prompt")

    system_msg='{"role":"system","content":"just If you need to execute an operation, generate a script in sh (not bash) outputing code inside ```sh ... ``` so you get the output if you needed. don t abuse it and output text normally"}'

    # Recupera thread esistente per questo chat_id
    # FIX: \(...\) invece di (...) per POSIX sed
    thread=$(sed -n "s/.*\"$chat_id\":\[\(.*\)\].*/\1/p" "$FILE")
    [ -z "$thread" ] && thread=""

    if [ -n "$thread" ]; then
        thread="$thread,"
    fi

    # FIX: usa \" esplicitamente per costruire JSON valido
    thread="${thread}{\"role\":\"user\",\"content\":\"$prompt_escaped\"}"

    json="{\"model\":\"$model\",\"messages\":[ $system_msg, $thread ]}"

    answer=$(wget -q -O - \
        --header="Content-Type: application/json" \
        --post-data="$json" \
        https://watchllm.vercel.app/api/proxy)

    echo "$answer"
    echo ""

    # Estrai il campo content dalla risposta JSON
    # FIX: \(...\) per POSIX sed
    content=$(echo "$answer" | sed -n 's/.*"content":"\([^"]*\)".*/\1/p')
    reply=$(printf '%s' "$content" | sed 's/"/\\"/g')

    thread="${thread},{\"role\":\"assistant\",\"content\":\"$reply\"}"

    tmp=$(mktemp)

    # Escape per il REPLACEMENT di sed: \, &, e | (delimitatore usato sotto)
    # FIX: aggiunto | b

    escaped_thread=$(printf '%s' "$thread" | sed 's/[\\&|]/\\&/g')

if grep -q "\"$chat_id\"" "$FILE"; then
    # chat già esistente → sostituisci il contenuto
        sed "s|\"$chat_id\":\[[^]]*\]|\"$chat_id\":[ $escaped_thread ]|" "$FILE" > "$tmp"
        else
            if [ "$(tr -d '[:space:]' < "$FILE")" = "{}" ]; then
                    # file vuoto → crea struttura valida da zero
                            printf '{"%s":[ %s ]}\n' "$chat_id" "$thread" > "$tmp"
                                else
                                        # aggiungi nuova chat PRIMA della chiusura }
                                                sed "s|}|,\"$chat_id\":[ $escaped_thread ]}|" "$FILE" > "$tmp"
                                                    fi
                                                    fi

                                                    mv "$tmp" "$FILE"

    # =========================
    # ESTRAI CODICE
    # =========================
    # FIX: pattern corretto per i fence markdown ```sh / ```bash
run=$(printf '%s\n' "$answer" | awk '
    /^```(sh|bash)[[:space:]]*$/ { flag=1; next }
        /^```[[:space:]]*$/          { flag=0 }
            flag && NF                   { print }
            ')

    # Se non recursive o nessun codice trovato, esci
    [ "$recursive" -eq 0 ] && break
    [ -z "$run" ]          && break


echo ">>> Eseguo:"
echo "$run"
output=$(sh -c "$run" 2>&1)
echo ">>> Output:"
echo "$output"

# =========================
# ANTI LOOP (QUI ESATTAMENTE)
# =========================
[ "$run" = "$last_run" ] && break
[ "$output" = "$last_output" ] && break

last_run="$run"
last_output="$output"



    # printf interpreta \n come vero newline b
    prompt=$(printf 'Output comando:\n%s' "$output")
done
