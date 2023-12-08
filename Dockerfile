FROM node:21.4.0-alpine@sha256:9bfaec4816d320226b1533abd5d22d6a888105ee502b820676736de99a198408 AS builder

WORKDIR /app

COPY .yarn/ .yarn/
COPY package.json yarn.lock .yarnrc.yml .pnp* ./
RUN yarn install

COPY ./src ./src
COPY ./tsconfig.json ./

RUN yarn build

# ---

FROM node:21.4.0-alpine@sha256:9bfaec4816d320226b1533abd5d22d6a888105ee502b820676736de99a198408

WORKDIR /app

COPY .yarn/ .yarn/
COPY package.json yarn.lock .yarnrc.yml .pnp* ./
RUN yarn workspaces focus --all --production

COPY --from=builder /app/build /app/build

CMD yarn start
