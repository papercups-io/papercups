FROM elixir:1.11.3-alpine as builder

# build step
ARG MIX_ENV=prod
ARG NODE_ENV=production
ARG APP_VER=0.0.1
ARG USE_IP_V6=false
ARG REQUIRE_DB_SSL=false
ARG AWS_ACCESS_KEY_ID
ARG AWS_SECRET_ACCESS_KEY
ARG BUCKET_NAME
ARG AWS_REGION
ARG PAPERCUPS_STRIPE_SECRET

ENV APP_VERSION=$APP_VER
ENV REQUIRE_DB_SSL=$REQUIRE_DB_SSL
ENV USE_IP_V6=$USE_IP_V6
ENV AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
ENV AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
ENV BUCKET_NAME=$BUCKET_NAME
ENV AWS_REGION=$AWS_REGION
ENV PAPERCUPS_STRIPE_SECRET=$PAPERCUPS_STRIPE_SECRET


RUN mkdir /app
WORKDIR /app

RUN apk add --no-cache git nodejs yarn python3 npm ca-certificates wget gnupg make erlang gcc libc-dev && \
    npm install npm@latest -g

# Client side
COPY assets/package.json assets/package-lock.json ./assets/
RUN npm install --prefix=assets

# fix because of https://github.com/facebook/create-react-app/issues/8413
ENV GENERATE_SOURCEMAP=false

COPY priv priv
COPY assets assets
RUN npm run build --prefix=assets

COPY mix.exs mix.lock ./
COPY config config

RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get --only prod

COPY lib lib
RUN mix deps.compile
RUN mix phx.digest priv/static

WORKDIR /app
COPY rel rel
RUN mix release papercups

FROM alpine:3.13 AS app
RUN apk add --no-cache openssl ncurses-libs
ENV LANG=C.UTF-8
EXPOSE 4000

WORKDIR /app

ENV HOME=/app

RUN adduser -h /app -u 1000 -s /bin/sh -D papercupsuser

COPY --from=builder --chown=papercupsuser:papercupsuser /app/_build/prod/rel/papercups /app
COPY --from=builder --chown=papercupsuser:papercupsuser /app/priv /app/priv
RUN chown -R papercupsuser:papercupsuser /app

COPY docker-entrypoint.sh /entrypoint.sh
RUN chmod a+x /entrypoint.sh

USER papercupsuser

WORKDIR /app
ENTRYPOINT ["/entrypoint.sh"]
CMD ["run"]
