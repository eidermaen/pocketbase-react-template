#!/bin/sh
set -e

if [ "$(id -u)" = "0" ]; then
	chown -R appuser:appuser /app/pb_data
	exec su-exec appuser "$0" "$@"
fi

./app migrate up --dir ./pb_data
exec ./app serve --http=0.0.0.0:8090 --dir ./pb_data
