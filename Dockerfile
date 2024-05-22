FROM node:21.7.3-alpine@sha256:d44678a321331f2f003b51303cc5105f9787637e0524cf94d4323d08050a99c9 AS builder

WORKDIR /app

COPY .yarn/ .yarn/
COPY package.json yarn.lock .yarnrc.yml .pnp* ./
RUN yarn install

COPY ./src ./src
COPY ./tsconfig.json ./

RUN yarn build

# ---

FROM node:21.7.3-alpine@sha256:d44678a321331f2f003b51303cc5105f9787637e0524cf94d4323d08050a99c9

WORKDIR /app

COPY .yarn/ .yarn/
COPY package.json yarn.lock .yarnrc.yml .pnp* ./
RUN yarn workspaces focus --all --production

COPY --from=builder /app/build /app/build

CMD yarn start
