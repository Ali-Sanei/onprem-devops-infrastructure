FROM alpine:3.20 
WORKDIR /app
COPY app.sh version.txt health.sh./
RUN chmod +x app.sh health.sh
CMD ["./app.sh"]
