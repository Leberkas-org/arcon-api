FROM node:22-alpine

RUN apk add --no-cache bash python3 py3-pip pipx
RUN pipx install envtpl

ENV PATH="/root/.local/bin:$PATH"
RUN npm install -g @redocly/cli@latest

WORKDIR /api

COPY scripts/ scripts/

ENV STATIC_HTML_DOCS=1
ENV API_VERSION=local-dev

CMD ["bash", "scripts/build.sh"]
