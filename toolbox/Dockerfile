FROM hashicorp/terraform:1.13.4 AS terraform
FROM grafana/k6:1.3.0 AS k6
FROM alpine/helm:3.19.0 AS helm
FROM docker:28.5.1-cli
RUN apk add --no-cache bash curl git jq python3 openssl
RUN git config --system --add safe.directory /workspace
COPY --from=terraform /bin/terraform /usr/local/bin/terraform
COPY --from=k6 /usr/bin/k6 /usr/local/bin/k6
COPY --from=helm /usr/bin/helm /usr/local/bin/helm
ARG TARGETARCH
RUN curl -fsSL https://dl.k8s.io/release/v1.33.5/bin/linux/${TARGETARCH}/kubectl -o /usr/local/bin/kubectl && chmod +x /usr/local/bin/kubectl \
 && curl -fsSL https://github.com/k3d-io/k3d/releases/download/v5.8.3/k3d-linux-${TARGETARCH} -o /usr/local/bin/k3d && chmod +x /usr/local/bin/k3d
WORKDIR /workspace
CMD ["sleep", "infinity"]
