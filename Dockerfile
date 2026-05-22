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
RUN apk add --no-cache nginx supervisor wget mariadb mariadb-client

WORKDIR /app
COPY --from=backend-build /app/backend/target/*.jar /app/app.jar
COPY --from=frontend-build /app/frontend/dist /usr/share/nginx/html
COPY docker/nginx.conf /etc/nginx/http.d/default.conf
COPY docker/supervisord.conf /etc/supervisord.conf
COPY docker/mysql-start.sh /usr/local/bin/mysql-start.sh
COPY docker/backend-start.sh /usr/local/bin/backend-start.sh
COPY billing_app.sql /docker-entrypoint-initdb.d/billing_app.sql

RUN mkdir -p /run/nginx /run/mysqld /var/log/supervisor /app/uploads /docker-entrypoint-initdb.d \
    && chmod +x /usr/local/bin/mysql-start.sh /usr/local/bin/backend-start.sh

ENV SERVER_PORT=8080
ENV MYSQL_DATABASE=billing_app
ENV MYSQL_ROOT_PASSWORD=change-me-in-production
ENV SPRING_DATASOURCE_URL=jdbc:mariadb://127.0.0.1:3306/billing_app
ENV SPRING_DATASOURCE_DRIVER_CLASS_NAME=org.mariadb.jdbc.Driver
ENV SPRING_DATASOURCE_USERNAME=root
EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=120s --retries=3 \
  CMD wget -qO- http://127.0.0.1/ >/dev/null || exit 1

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
