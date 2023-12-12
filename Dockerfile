ARG NODE_VERSION=20

FROM node:${NODE_VERSION}-bullseye as ncr

## Tried alpine...
# RUN apk update && apk add curl git make
# RUN wget -qO- https://get.pnpm.io/install.sh | ENV="$HOME/.shrc" SHELL="$(which sh)" sh - && source /root/.shrc && \
 # git clone https://github.com/ForkbombEu/ncr.git /ncr-app && cd /ncr-app && make build && chmod +x ncr

RUN apt update && apt install curl git make
RUN corepack enable && corepack prepare pnpm@latest --activate && \
	git clone https://github.com/ForkbombEu/ncr.git /ncr-app && \
	cd /ncr-app && make build && chmod +x ncr
WORKDIR /ncr-app


FROM debian:bullseye
WORKDIR /app
ARG PORT=3000
ENV PORT $PORT
COPY authz_server/ authz_server
COPY credential_issuer/ credential_issuer
COPY public/ public/
COPY --from=ncr /ncr-app/ncr .
EXPOSE $PORT
ENTRYPOINT ["./ncr", "-z", ".", "--public-directory", "public"]
