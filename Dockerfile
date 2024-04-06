FROM node:21.7.2-alpine@sha256:ad255c65652e8e99ce0b9d9fc52eee3eae85f445b192f6f9e49a1305c77b2ba6 AS builder

WORKDIR /app

COPY .yarn/ .yarn/
COPY package.json yarn.lock .yarnrc.yml .pnp* ./
RUN yarn install

COPY ./src ./src
COPY ./tsconfig.json ./

RUN yarn build

# ---

FROM node:21.7.2-alpine@sha256:ad255c65652e8e99ce0b9d9fc52eee3eae85f445b192f6f9e49a1305c77b2ba6

WORKDIR /app

COPY .yarn/ .yarn/
COPY package.json yarn.lock .yarnrc.yml .pnp* ./
RUN yarn workspaces focus --all --production

COPY --from=builder /app/build /app/build

CMD yarn start
