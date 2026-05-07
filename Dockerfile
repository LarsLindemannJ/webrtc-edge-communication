FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm install --omit=dev

COPY server ./server
COPY public ./public

EXPOSE 8080
EXPOSE 8443

CMD ["npm", "start"]
