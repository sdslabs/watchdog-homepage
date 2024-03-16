FROM node:20-alpine

RUN mkdir -p /home/$USER/watchdog-homepage 

WORKDIR /home/$USER/watchdog-homepage 

COPY package*.json ./

RUN npm install

COPY . .

EXPOSE 8089

CMD ["npm", "start"]
