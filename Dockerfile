FROM node:18-alpine
WORKDIR /app
COPY package.json .
RUN npm install
COPY server ./server
COPY public ./public
COPY cert ./cert
EXPOSE 8080
EXPOSE 8443
CMD ["npm", "start"]
