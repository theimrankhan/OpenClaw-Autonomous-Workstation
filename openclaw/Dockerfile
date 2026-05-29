FROM ubuntu:24.04

ARG OPENCLAW_GIT_URL=https://github.com/openclaw/openclaw.git
ARG OPENCLAW_BRANCH=main

ENV DEBIAN_FRONTEND=noninteractive \
    OPENCLAW_HOME=/opt/openclaw \
    OPENCLAW_PORT=8080

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      ca-certificates curl git jq nodejs npm python3 python3-pip python3-venv bash docker.io \
    && rm -rf /var/lib/apt/lists/*

RUN useradd --system --create-home --home-dir /opt/openclaw --shell /usr/sbin/nologin openclaw \
    && mkdir -p /opt/openclaw/{app,config,workspace,memory,skills,tools,logs,data} \
    && chown -R openclaw:openclaw /opt/openclaw

USER openclaw
RUN git clone --branch "$OPENCLAW_BRANCH" "$OPENCLAW_GIT_URL" /opt/openclaw/app || true
WORKDIR /opt/openclaw/app
RUN if [ -f package.json ]; then npm ci || npm install; fi \
    && if [ -f requirements.txt ]; then python3 -m venv /opt/openclaw/venv && /opt/openclaw/venv/bin/pip install -r requirements.txt; fi

COPY --chown=openclaw:openclaw config.yaml /opt/openclaw/config/config.yaml
COPY --chown=openclaw:openclaw skills.yaml /opt/openclaw/skills/skills.yaml
COPY --chown=openclaw:openclaw entrypoint.sh /opt/openclaw/entrypoint.sh
USER root
RUN chmod 0755 /opt/openclaw/entrypoint.sh
USER openclaw

EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=10s --retries=5 CMD curl -fsS http://127.0.0.1:8080/health || exit 1
ENTRYPOINT ["/opt/openclaw/entrypoint.sh"]
