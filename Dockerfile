FROM node:21.2.0-alpine@sha256:5fc1d095e47286b0859342a7b8a90b1c3adf2c283f12c6542a5456c1f2955218 AS builder

WORKDIR /app

COPY .yarn/ .yarn/
COPY package.json yarn.lock .yarnrc.yml .pnp* ./
RUN yarn install

COPY ./src ./src
COPY ./tsconfig.json ./

RUN yarn build

# ---

FROM node:21.2.0-alpine@sha256:5fc1d095e47286b0859342a7b8a90b1c3adf2c283f12c6542a5456c1f2955218

WORKDIR /app

COPY .yarn/ .yarn/
COPY package.json yarn.lock .yarnrc.yml .pnp* ./
RUN yarn workspaces focus --all --production

COPY --from=builder /app/build /app/build

CMD yarn start
