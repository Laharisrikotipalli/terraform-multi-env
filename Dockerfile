FROM hashicorp/terraform:1.9.5 AS terraform
FROM infracost/infracost:ci-0.10 AS infracost

FROM alpine:3.20

RUN apk add --no-cache \
    bash \
    curl \
    unzip \
    git \
    jq \
    python3 \
    py3-pip \
    ca-certificates \
    groff \
    less

COPY --from=terraform /bin/terraform /usr/local/bin/terraform
COPY --from=infracost /usr/bin/infracost /usr/local/bin/infracost

RUN pip3 install --no-cache-dir --break-system-packages awscli \
    && terraform version \
    && infracost --version \
    && aws --version

RUN addgroup -S iac && adduser -S -G iac -h /home/iac iac \
    && mkdir -p /home/iac/.terraform.d/plugin-cache \
    && chown -R iac:iac /home/iac

USER iac
WORKDIR /workspace