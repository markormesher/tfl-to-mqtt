FROM node:21.7.1-alpine@sha256:4999fa1391e09259e71845d3d0e9ddfe5f51ab30253c8b490c633f710c7446a0 AS builder

WORKDIR /app

COPY .yarn/ .yarn/
COPY package.json yarn.lock .yarnrc.yml .pnp* ./
RUN yarn install

COPY ./src ./src
COPY ./tsconfig.json ./

RUN yarn build

# ---

FROM node:21.7.1-alpine@sha256:4999fa1391e09259e71845d3d0e9ddfe5f51ab30253c8b490c633f710c7446a0

WORKDIR /app

COPY .yarn/ .yarn/
COPY package.json yarn.lock .yarnrc.yml .pnp* ./
RUN yarn workspaces focus --all --production

COPY --from=builder /app/build /app/build

CMD yarn start
