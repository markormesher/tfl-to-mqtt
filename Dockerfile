FROM node:21.7.1-alpine@sha256:92701a26dafc0e33c87fc245537b39af27da2be9736c84ed4f6f100c7d7194b0 AS builder

WORKDIR /app

COPY .yarn/ .yarn/
COPY package.json yarn.lock .yarnrc.yml .pnp* ./
RUN yarn install

COPY ./src ./src
COPY ./tsconfig.json ./

RUN yarn build

# ---

FROM node:21.7.1-alpine@sha256:92701a26dafc0e33c87fc245537b39af27da2be9736c84ed4f6f100c7d7194b0

WORKDIR /app

COPY .yarn/ .yarn/
COPY package.json yarn.lock .yarnrc.yml .pnp* ./
RUN yarn workspaces focus --all --production

COPY --from=builder /app/build /app/build

CMD yarn start
