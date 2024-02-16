FROM node:21.6.2-alpine@sha256:d3271e4bd89eec4d97087060fd4db0c238d9d22fcfad090a73fa9b5128699888 AS builder

WORKDIR /app

COPY .yarn/ .yarn/
COPY package.json yarn.lock .yarnrc.yml .pnp* ./
RUN yarn install

COPY ./src ./src
COPY ./tsconfig.json ./

RUN yarn build

# ---

FROM node:21.6.2-alpine@sha256:d3271e4bd89eec4d97087060fd4db0c238d9d22fcfad090a73fa9b5128699888

WORKDIR /app

COPY .yarn/ .yarn/
COPY package.json yarn.lock .yarnrc.yml .pnp* ./
RUN yarn workspaces focus --all --production

COPY --from=builder /app/build /app/build

CMD yarn start
