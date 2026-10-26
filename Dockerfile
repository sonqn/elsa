FROM python:3.13-alpine AS build
WORKDIR /build
COPY app/main.py .
RUN python -m py_compile main.py
FROM python:3.13-alpine
RUN addgroup -g 10001 app && adduser -D -u 10001 -G app app
WORKDIR /app
COPY --from=build /build/main.py .
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
USER 10001:10001
EXPOSE 8080
CMD ["python", "main.py"]
