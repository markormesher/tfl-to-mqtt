FROM node:21.7.3-alpine@sha256:c986eb0b8970240f8d648e524bab46016b78f290f912aac16a4aa6705dde05f4 AS builder

WORKDIR /app

COPY .yarn/ .yarn/
COPY package.json yarn.lock .yarnrc.yml .pnp* ./
RUN yarn install

COPY ./src ./src
COPY ./tsconfig.json ./

RUN yarn build

# ---

FROM node:21.7.3-alpine@sha256:c986eb0b8970240f8d648e524bab46016b78f290f912aac16a4aa6705dde05f4

WORKDIR /app

COPY .yarn/ .yarn/
COPY package.json yarn.lock .yarnrc.yml .pnp* ./
RUN yarn workspaces focus --all --production

COPY --from=builder /app/build /app/build

CMD yarn start
