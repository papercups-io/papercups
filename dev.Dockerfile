ARG MIX_ENV=dev
FROM elixir:1.10 as dev
ENV MIX_HOME=/opt/mix

WORKDIR /usr/src/app
ENV LANG=C.UTF-8

RUN curl -sL https://deb.nodesource.com/setup_12.x | bash - && \
    apt-get install -y nodejs fswatch && \
    mix local.hex --force && \
    mix local.rebar --force

# declared here since they are required at build and run time.
ENV DATABASE_URL="ecto://postgres:postgres@localhost/chat_api" SECRET_KEY_BASE="" MIX_ENV=dev FROM_ADDRESS="" MAILGUN_API_KEY=""

COPY mix.exs mix.lock ./
COPY config config
RUN mix do deps.get, deps.compile

COPY assets/package.json assets/package-lock.json ./assets/
RUN npm install --prefix=assets

# Temporary fix because of https://github.com/facebook/create-react-app/issues/8413
ENV GENERATE_SOURCEMAP=false

COPY priv priv
COPY assets assets
RUN npm run build --prefix=assets

COPY lib lib
RUN mix do compile
RUN mix phx.digest

COPY docker-entrypoint-dev.sh entrypoint.sh
CMD ["/usr/src/app/entrypoint.sh"]
