# syntax=docker/dockerfile:1

FROM node:22-alpine AS frontend-build
WORKDIR /app/frontend
COPY frontend/package.json frontend/package-lock.json ./
RUN npm ci
COPY frontend/ ./
RUN npm run build

FROM golang:1.27-alpine AS backend-build
RUN apk add --no-cache gcc musl-dev
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
COPY --from=frontend-build /app/frontend/dist ./frontend/dist
RUN CGO_ENABLED=1 go build -o /app/bin/app ./cmd/start

FROM alpine:latest
RUN apk add --no-cache ca-certificates tzdata su-exec
RUN addgroup -g 1000 appuser && adduser -D -u 1000 -G appuser appuser
WORKDIR /app
COPY --from=backend-build /app/bin/app ./app
COPY docker-entrypoint.sh ./
RUN chmod +x docker-entrypoint.sh
VOLUME /app/pb_data
EXPOSE 8090
ENTRYPOINT ["./docker-entrypoint.sh"]
