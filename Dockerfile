# Build stage
FROM node:22-alpine3.22

ENV NODE_ENV=production

WORKDIR /quickchart

RUN apk add --upgrade apk-tools
RUN apk add --no-cache --virtual .build-deps yarn git build-base g++ python3
RUN apk add --no-cache --virtual .npm-deps cairo-dev pango-dev libjpeg-turbo-dev librsvg-dev
RUN apk add --no-cache --virtual .fonts libmount ttf-dejavu ttf-droid ttf-freefont ttf-liberation font-noto font-noto-emoji fontconfig
RUN apk add --no-cache --repository https://dl-cdn.alpinelinux.org/alpine/edge/community font-wqy-zenhei
RUN apk add --no-cache libimagequant-dev
RUN apk add --no-cache vips-dev
RUN apk add --no-cache --virtual .runtime-deps graphviz

COPY package*.json .

RUN yarn install --production

RUN apk update
RUN rm -rf /var/cache/apk/* && \
    rm -rf /tmp/*
RUN apk del .build-deps

COPY *.js ./
COPY lib/*.js lib/
COPY LICENSE .

RUN export NODE_ENV=development && \
    yarn add webpack@4 && \
    yarn add webpack-cli@4 && \
    yarn add webpack-node-externals && \
    export NODE_ENV=production && \
    yarn build && \
    apk add g++ make && \
    yarn remove webpack


# Final stage
FROM node:22-alpine3.22

COPY --from=0 /quickchart/dist/* /quickchart/dist/
COPY --from=0 /quickchart/node_modules /quickchart/node_modules/

RUN apk update && \
    apk upgrade && \
    apk add \
    cairo \
    pango \
    libjpeg-turbo \
    librsvg \
    ttf-dejavu \
    ttf-droid \
    ttf-freefont \
    ttf-liberation \
    font-noto \
    font-noto-emoji && \
    rm -rf /var/cache/apk/*

WORKDIR /quickchart

ENV NODE_ENV=production

EXPOSE 3400

ENTRYPOINT ["node", "--max-http-header-size=65536", "dist/bundle.js"]

