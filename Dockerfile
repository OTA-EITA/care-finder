# syntax=docker/dockerfile:1
# check=error=true

# 本番用イメージ（ECS Fargate で動かす）。手元での確認:
#   docker build -t care-finder .
#   docker run --rm -p 3000:3000 -e SECRET_KEY_BASE=$(openssl rand -hex 64) -e DB_HOST=... -e DB_PREPARE_ON_BOOT=1 care-finder

ARG RUBY_VERSION=4.0.9
ARG NODE_VERSION=24.22.1

# --- JS / CSS のビルド（Node はこの段階だけで使い、最終イメージには入れない） ---
FROM docker.io/library/node:${NODE_VERSION}-bookworm-slim AS assets
WORKDIR /app
COPY package.json package-lock.json .npmrc ./
RUN npm ci --ignore-scripts
COPY app/javascript ./app/javascript
COPY app/assets/stylesheets ./app/assets/stylesheets
COPY app/views ./app/views
COPY app/helpers ./app/helpers
COPY tsconfig.json ./
RUN mkdir -p app/assets/builds && npm run build && npm run build:css

# --- Ruby の共通部分 ---
FROM docker.io/library/ruby:${RUBY_VERSION}-slim AS base
WORKDIR /rails

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl default-mysql-client libjemalloc2 && \
    ln -s /usr/lib/$(uname -m)-linux-gnu/libjemalloc.so.2 /usr/local/lib/libjemalloc.so && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test" \
    LD_PRELOAD="/usr/local/lib/libjemalloc.so"

# --- gem のビルドとアセットのダイジェスト付与 ---
FROM base AS build

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential default-libmysqlclient-dev git libyaml-dev pkg-config && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

COPY vendor/* ./vendor/
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile -j 1 --gemfile

COPY . .
COPY --from=assets /app/app/assets/builds ./app/assets/builds

RUN bundle exec bootsnap precompile -j 1 app/ lib/

# JS / CSS は assets 段階でビルド済みなので、ここではダイジェスト付与だけを行う
RUN SECRET_KEY_BASE_DUMMY=1 SKIP_JS_BUILD=1 SKIP_CSS_BUILD=1 ./bin/rails assets:precompile

# --- 実行用イメージ（root 以外で動かす） ---
FROM base

RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash
USER 1000:1000

COPY --chown=rails:rails --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --chown=rails:rails --from=build /rails /rails

ENTRYPOINT ["/rails/bin/docker-entrypoint"]

EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s --start-period=30s CMD curl -fsS http://127.0.0.1:3000/up || exit 1
CMD ["./bin/rails", "server", "-b", "0.0.0.0", "-p", "3000"]
