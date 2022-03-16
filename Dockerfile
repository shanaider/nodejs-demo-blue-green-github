from docker-registry.default.svc:5000/bkk-test/node:12-alpine

COPY . .

RUN npm install

RUN addgroup -S appgroup && adduser --uid 10030700 -S appuser -G appgroup -h /home/appuser 
USER appuser
CMD node main.js
