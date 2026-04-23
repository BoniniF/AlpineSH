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

# Escape delle virgolette per JSON
# FIX: doppio backslash b
escape() {
    printf '%s' "$1" | sed 's/"/\\"/g'
}

# =========================
# LOOP (per recursive)
# =========================
while :; do
    prompt_escaped=$(escape "$prompt")

    system_msg='{"role":"system","content":"If you need to execute an operation, generate a script in sh (not bash). Output only code inside ```sh ... ```"}'

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

    # Escape per il REPLACEMENT di sed: solo \ e & vanno escapati
    # FIX: era 's/[/&|]/\&/g' che escapava caratteri sbagliati
    escaped_thread=$(printf '%s' "$thread" | sed 's/[\\&]/\\&/g')

    if grep -q "\"$chat_id\"" "$FILE"; then
        sed "s|\"$chat_id\":\[[^]]*\]|\"$chat_id\":[ $escaped_thread ]|" "$FILE" > "$tmp"
    else
        sed "s|}|,\"$chat_id\":[ $escaped_thread ]}|" "$FILE" > "$tmp"
    fi
    mv "$tmp" "$FILE"

    # =========================
    # ESTRAI CODICE
    # =========================
    # FIX: pattern corretto per i fence markdown ```sh / ```bash
    run=$(echo "$answer" | awk '
        /```(sh|bash)/ { flag=1; next }
        /```/          { flag=0 }
        flag           { print }
    ')

    # Se non recursive o nessun codice trovato, esci
    [ "$recursive" -eq 0 ] && break
    [ -z "$run" ]          && break

    echo ">>> Eseguo:"
    echo "$run"
    output=$(echo "$run" | sh 2>&1)
    echo ">>> Output:"
    echo "$output"

    # Rimanda l'output come nuovo prompt; evita loop infinito
    [ "$output" = "$prompt" ] && break
    prompt="Output comando:\n$output"
done
