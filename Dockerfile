FROM node:21.2.0-alpine@sha256:4a512d1538b1a8281b58cab0b366a5c62436566bb63e7dcd4a6769c98edb3b5f AS builder

WORKDIR /app

COPY .yarn/ .yarn/
COPY package.json yarn.lock .yarnrc.yml .pnp* ./
RUN yarn install

COPY ./src ./src
COPY ./tsconfig.json ./

RUN yarn build

# ---

FROM node:21.2.0-alpine@sha256:4a512d1538b1a8281b58cab0b366a5c62436566bb63e7dcd4a6769c98edb3b5f

WORKDIR /app

COPY .yarn/ .yarn/
COPY package.json yarn.lock .yarnrc.yml .pnp* ./
RUN yarn workspaces focus --all --production

COPY --from=builder /app/build /app/build

CMD yarn start
