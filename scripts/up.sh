#!/usr/bin/env bash

UP_PORT=${1}
MS_NAME=${2}

if [ ! -x scripts/autorun_search.sh ]; then
    chmod +x scripts/autorun_search.sh
fi

if [ ! -x scripts/autorun_store.sh ]; then
    chmod +x scripts/autorun_store.sh
fi

function start_service() {
    service=$1
    echo "🐣 Starting service: ${service}"
    wk_name=""
    case ${service} in
        "authz_server")
            wk_name="oauth-authorization-server"
            ;;
        "credential_issuer")
            wk_name="openid-credential-issuer"
            ;;
        "relying_party")
            wk_name="openid-relying-party"
            ;;
        *)
            echo "Unknown value for ${service}. Nothing to do." >&2
            exit 1
            ;;
    esac
    name=${MS_NAME}
    if [ -z "${name}" ]; then name=$service; fi
    (
        MS_NAME=$name ./ncr -p $port -z $service --public-directory public/$service --basepath '/'$service &
        APP_PID=$!
        echo $APP_PID > .${service}.pid
        (
            sleep 5
            if [ ! -f $service/secrets.keys ]; then
                echo "📢 Announce phase failed"
                echo "🗝️  Secret keys not created in file: ${s}/secrets.keys"
                echo "⛔ Stopping the service"
                kill $APP_PID
                exit 1
            fi
            kid=$(jq -r '.jwks.keys[0].kid' public/$service/.well-known/$wk_name)
            if [ "${kid:0:1}" = "{" ]; then
                echo "📢 Announce phase failed"
                echo "🪪 Kid not created in file: public/$service/.well-known/$wk_name"
                echo "⛔ Stopping the service"
                kill $APP_PID
                exit 1
            fi
        )
        wait $APP_PID
    )
}


service=$(ls | grep -E "authz_server$|credential_issuer$|relying_party$" --color=never)
if [ -z "${service}" ]; then
    echo "😢 No service found"
    exit 1
fi

port=${UP_PORT}
if [ "$(echo ${service} | wc -w)" = "1" ]; then
    start_service ${service} ${port}
else
    for s in ${service}; do
        start_service ${s} ${port} &
        port=$((port+1))
    done
fi