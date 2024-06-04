FROM node:21.7.3-alpine@sha256:fe8d99fad66b7578d9ee320b9295294538e6bd1207324288a65a46aa4cb712d9 AS builder

WORKDIR /app

COPY .yarn/ .yarn/
COPY package.json yarn.lock .yarnrc.yml .pnp* ./
RUN yarn install

COPY ./src ./src
COPY ./tsconfig.json ./

RUN yarn build

# ---

FROM node:21.7.3-alpine@sha256:fe8d99fad66b7578d9ee320b9295294538e6bd1207324288a65a46aa4cb712d9

WORKDIR /app

COPY .yarn/ .yarn/
COPY package.json yarn.lock .yarnrc.yml .pnp* ./
RUN yarn workspaces focus --all --production

COPY --from=builder /app/build /app/build

CMD yarn start
