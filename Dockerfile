FROM node:21.7.3-alpine@sha256:db8772d9f5796ac4e8c47508038c413ea1478da010568a2e48672f19a8b80cd2 AS builder

WORKDIR /app

COPY .yarn/ .yarn/
COPY package.json yarn.lock .yarnrc.yml .pnp* ./
RUN yarn install

COPY ./src ./src
COPY ./tsconfig.json ./

RUN yarn build

# ---

FROM node:21.7.3-alpine@sha256:db8772d9f5796ac4e8c47508038c413ea1478da010568a2e48672f19a8b80cd2

WORKDIR /app

COPY .yarn/ .yarn/
COPY package.json yarn.lock .yarnrc.yml .pnp* ./
RUN yarn workspaces focus --all --production

COPY --from=builder /app/build /app/build

CMD yarn start
