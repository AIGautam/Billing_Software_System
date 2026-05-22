FROM node:22-alpine AS frontend-build
WORKDIR /app/frontend
ARG VITE_RAZORPAY_KEY_ID
ENV VITE_RAZORPAY_KEY_ID=$VITE_RAZORPAY_KEY_ID
COPY frontend/package*.json ./
RUN npm ci
COPY frontend/ ./
RUN npm run build

FROM eclipse-temurin:21-jdk-alpine AS backend-build
WORKDIR /app/backend
COPY backend/.mvn ./.mvn
COPY backend/mvnw backend/pom.xml ./
RUN chmod +x mvnw && ./mvnw -q dependency:go-offline
COPY backend/src ./src
RUN ./mvnw -q clean package

FROM eclipse-temurin:21-jre-alpine
RUN apk add --no-cache nginx supervisor wget

WORKDIR /app
COPY --from=backend-build /app/backend/target/*.jar /app/app.jar
COPY --from=frontend-build /app/frontend/dist /usr/share/nginx/html
COPY docker/nginx.conf /etc/nginx/http.d/default.conf
COPY docker/supervisord.conf /etc/supervisord.conf

RUN mkdir -p /run/nginx /var/log/supervisor /app/uploads

ENV SERVER_PORT=8080
EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=40s --retries=3 \
  CMD wget -qO- http://127.0.0.1/ >/dev/null || exit 1

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
