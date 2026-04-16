
#!/bin/sh

FILE="conversations.json"

prompt="$*"
model="nvidia/nemotron-nano-12b-v2-vl"
chat_id="0"

# parsing --chat
if [ "$1" = "--chat" ]; then
    chat_id="$2"
        shift 2
            prompt="$*"
            fi

            # crea file se non esiste
            [ ! -f "$FILE" ] && echo "{}" > "$FILE"

            # escape JSON
            prompt_escaped=$(printf '%s' "$prompt" | sed 's/"/\\"/g')

            # prendi thread (solo contenuto tra [])
            thread=$(sed -n "s/.*\"$chat_id\":\[\(.*\)\].*/\1/p" "$FILE")

            # se vuoto
            [ -z "$thread" ] && thread=""

            # aggiungi virgola se serve
            if [ -n "$thread" ]; then
                thread="$thread,"
                fi

                # aggiungi nuovo messaggio
                thread="$thread{\"role\":\"user\",\"content\":\"$prompt_escaped\"}"

                # costruisci JSON
                json="{\"model\":\"$model\",\"messages\":[ $thread ]}"

                # richiesta
                answer=$(wget -q -O - \
                --header="Content-Type: application/json" \
                --post-data="$json" \
                https://watchllm.vercel.app/api/proxy)

                echo "$answer"
                echo ""

                # estrai risposta (grezzo ma funziona col tuo proxy)
                reply=$(echo "$answer" | sed 's/"/\\"/g')

                # aggiorna thread con assistant
                thread="$thread,{\"role\":\"assistant\",\"content\":\"$reply\"}"

                # salva file (overwrite semplice)
                echo "{\"$chat_id\":[ $thread ]}" > "$FILE"

                # esegui codice
                run=$(echo "$answer" | sed -n '/^```\(sh\|bash\)/,/^```/ { /^```/d; p; }')
                echo "$run" | sh

                
