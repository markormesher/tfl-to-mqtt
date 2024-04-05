FROM node:21.7.2-alpine@sha256:6b840bf0506e8dfd3e3ce9e8c0cfb7c21333cdedabb25425b6ddc555d5df2442 AS builder

WORKDIR /app

COPY .yarn/ .yarn/
COPY package.json yarn.lock .yarnrc.yml .pnp* ./
RUN yarn install

COPY ./src ./src
COPY ./tsconfig.json ./

RUN yarn build

# ---

FROM node:21.7.2-alpine@sha256:6b840bf0506e8dfd3e3ce9e8c0cfb7c21333cdedabb25425b6ddc555d5df2442

WORKDIR /app

COPY .yarn/ .yarn/
COPY package.json yarn.lock .yarnrc.yml .pnp* ./
RUN yarn workspaces focus --all --production

COPY --from=builder /app/build /app/build

CMD yarn start
