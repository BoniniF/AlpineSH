#!/bin/sh

prompt="${1:-Hi}"

model="${2:-nvidia/nemotron-nano-12b-v2-vl}"

#echo "answer=\$(wget -q -O - --header=\'Content-Type: application/json\' --post-data=\'{\"model\": \"$model\", \"messages\": [{\"role\": \"user\", \"content\": \"$prompt\"}]}\' https://watchllm.vercel.app/api/proxy)"

answer=$(wget -q -O - --header="Content-Type: application/json" --post-data="{\"model\": \"$model\", \"messages\": [{\"role\": \"user\", \"content\": \"$prompt\"}, {\"role\": \"system\", \"content\": \"se l'utente richide di eseguire azioni, restituisci uno script sh (non bash)\"}]}" https://watchllm.vercel.app/api/proxy )
#echo " wget -q -O - --header=\"Content-Type: application/json\" --post-data=\"{\"model\": \"$model\", \"messages\": [{\"role\": \"user\", \"content\": \"$prompt\"}]}\" https://watchllm.vercel.app/api/proxy "

echo "$answer"
echo ""


run=$(echo "$answer" | sed -n '/^```\(sh\|bash\)/,/^```/ { /^```/d; p; }')
echo "$run" | sh
