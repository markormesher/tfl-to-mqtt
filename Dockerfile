FROM node:21.6.0-alpine@sha256:ab620cffd0f4d4529ef97682b2309c0571cd14a75496aa0934a13b059d003647 AS builder

WORKDIR /app

COPY .yarn/ .yarn/
COPY package.json yarn.lock .yarnrc.yml .pnp* ./
RUN yarn install

COPY ./src ./src
COPY ./tsconfig.json ./

RUN yarn build

# ---

FROM node:21.6.0-alpine@sha256:ab620cffd0f4d4529ef97682b2309c0571cd14a75496aa0934a13b059d003647

WORKDIR /app

COPY .yarn/ .yarn/
COPY package.json yarn.lock .yarnrc.yml .pnp* ./
RUN yarn workspaces focus --all --production

COPY --from=builder /app/build /app/build

CMD yarn start
