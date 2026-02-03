#!/bin/sh

echo "MyApp version $(cat version.txt) is running"

# fake web server
while true; do
  echo "HTTP/1.1 200 OK\n\nMyApp is alive" | nc -l -p 8080
done

