curl -u 07607d3a-37e9-4ec3-a8f8-700b58161832:dT3swy0NpmV3 -X POST --header "Content-Type: application/json" --header "Accept: audio/flac" --data "{\"text\":\"$1\"}" "https://stream.watsonplatform.net/text-to-speech/api/v1/synthesize?voice=$2" > $3