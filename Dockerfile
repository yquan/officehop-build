FROM node:11.12-alpine as dev-stage

# make the 'app' folder the current working directory
WORKDIR /app

# copy both 'package.json' and 'package-lock.json' (if available)
COPY package*.json ./

# copy project files and folders to the current working directory (i.e. 'app' folder)
COPY . .

EXPOSE 8080

CMD npm run serve --mode development

# build stage
FROM node:latest as build-stage

WORKDIR /app

RUN sed -i 's/deb.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list && \
	apt-get update

RUN apt-get install -yq gconf-service libasound2 libatk1.0-0 libc6 libcairo2 libcups2 libdbus-1-3 \
libexpat1 libfontconfig1 libgcc1 libgconf-2-4 libgdk-pixbuf2.0-0 libglib2.0-0 libgtk-3-0 libnspr4 \
libpango-1.0-0 libpangocairo-1.0-0 libstdc++6 libx11-6 libx11-xcb1 libxcb1 libxcomposite1 \
libxcursor1 libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 libxss1 libxtst6 \
ca-certificates fonts-liberation libappindicator1 libnss3 lsb-release xdg-utils wget python make g++ gcc tree


COPY package*.json ./

RUN npm config set unsafe-perm=true

RUN npm i -g mirror-config-china --registry=https://registry.npm.taobao.org
# install project dependencies
RUN npm install

COPY . .

ARG VUE_MODE=production

RUN npm run build -- --mode $VUE_MODE

# quick hack to hopefully fix the 403 error on /en/listing/ and /zh/listing 
RUN cp dist/index.html dist/zh/listing
RUN cp dist/index.html dist/en/listing

RUN tree --du -h dist/zh
RUN tree --du -h dist/en

# production stage
FROM nginx:stable-alpine as production-stage

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build-stage /app/dist /usr/share/nginx/html

CMD nginx -g 'daemon off;'