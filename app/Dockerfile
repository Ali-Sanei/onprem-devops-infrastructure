FROM alpine:3.20 
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
WORKDIR /app
COPY app.sh version.txt health.sh ./
RUN chown -R appuser:appgroup /app
USER appuser
HEALTHCHECK --interval=10s --timeout=3s --retries=3 \
  CMD sh health.sh || exit 1
CMD ["./app.sh"]
