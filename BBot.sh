#!/bin/sh
if [ -n "$1" ]; then
prompt=$1
else
prompt="Hi"
fi

if [ -n "$2" ]; then
model=$2
else
model="nvidia/nemotron-nano-12b-v2-vl"
fi

#echo "answer=\$(wget -q -O - --header=\'Content-Type: application/json\' --post-data=\'{\"model\": \"$model\", \"messages\": [{\"role\": \"user\", \"content\": \"$prompt\"}]}\' https://watchllm.vercel.app/api/proxy)"

answer=$(wget -q -O - --header="Content-Type: application/json" --post-data="{\"model\": \"$model\", \"messages\": [{\"role\": \"user\", \"content\": \"$prompt\"}]}" https://watchllm.vercel.app/api/proxy)

echo $answer
