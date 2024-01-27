FROM node:21.6.0-alpine@sha256:2a36d0555fc8549605075459c51915fb5c3414e221304cdb346f7725e25c2217 AS builder

WORKDIR /app

COPY .yarn/ .yarn/
COPY package.json yarn.lock .yarnrc.yml .pnp* ./
RUN yarn install

COPY ./src ./src
COPY ./tsconfig.json ./

RUN yarn build

# ---

FROM node:21.6.0-alpine@sha256:2a36d0555fc8549605075459c51915fb5c3414e221304cdb346f7725e25c2217

WORKDIR /app

COPY .yarn/ .yarn/
COPY package.json yarn.lock .yarnrc.yml .pnp* ./
RUN yarn workspaces focus --all --production

COPY --from=builder /app/build /app/build

CMD yarn start
