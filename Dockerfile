FROM node:21.4.0-alpine@sha256:34556ba78497768394c896cca78c490f620e624ddacd4ebe47380c52e3e5cf79 AS builder

WORKDIR /app

COPY .yarn/ .yarn/
COPY package.json yarn.lock .yarnrc.yml .pnp* ./
RUN yarn install

COPY ./src ./src
COPY ./tsconfig.json ./

RUN yarn build

# ---

FROM node:21.4.0-alpine@sha256:34556ba78497768394c896cca78c490f620e624ddacd4ebe47380c52e3e5cf79

WORKDIR /app

COPY .yarn/ .yarn/
COPY package.json yarn.lock .yarnrc.yml .pnp* ./
RUN yarn workspaces focus --all --production

COPY --from=builder /app/build /app/build

CMD yarn start
