# https://github.com/hadolint/hadolint/issues/861
# hadolint ignore=DL3029
FROM --platform="${BUILDPLATFORM:-linux/amd64}" docker.io/library/busybox:1.36.1@sha256:ba76950ac9eaa407512c9d859cea48114eeff8a6f12ebaa5d32ce79d4a017dd8 as builder
RUN mkdir /.cache && touch -t 202101010000.00 /.cache

ARG TARGETOS=linux
ARG TARGETARCH=amd64
ARG TARGETVARIANT

RUN echo "Building for ${TARGETOS}/${TARGETARCH}/${TARGETVARIANT:-v1}"

WORKDIR /app
COPY goreleaser/dist dist

# NOTICE: See goreleaser.yml for the build paths.
RUN if [ "${TARGETARCH}" = 'amd64' ]; then \
        cp "dist/parca-agent-${TARGETARCH}_${TARGETOS}_${TARGETARCH}_${TARGETVARIANT:-v1}/parca-agent" . ; \
    elif [ "${TARGETARCH}" = 'arm' ]; then \
        cp "dist/parca-agent-${TARGETARCH}_${TARGETOS}_${TARGETARCH}_${TARGETVARIANT##v}/parca-agent" . ; \
    else \
        cp "dist/parca-agent-${TARGETARCH}_${TARGETOS}_${TARGETARCH}/parca-agent" . ; \
    fi
RUN chmod +x parca-agent

# hadolint ignore=DL3029
FROM --platform="${TARGETPLATFORM:-linux/amd64}" gcr.io/distroless/static@sha256:9be3fcc6abeaf985b5ecce59451acbcbb15e7be39472320c538d0d55a0834edc

LABEL \
    org.opencontainers.image.source="https://github.com/parca-dev/parca-agent" \
    org.opencontainers.image.url="https://github.com/parca-dev/parca-agent" \
    org.opencontainers.image.description="eBPF based always-on profiler auto-discovering targets in Kubernetes and systemd, zero code changes or restarts needed!" \
    org.opencontainers.image.licenses="Apache-2.0"

COPY --chown=0:0 --from=builder /app/parca-agent /bin/parca-agent
COPY --chown=0:0 parca-agent.yaml /bin/parca-agent.yaml
COPY --chown=0:0 --from=builder /app/dist/async-profiler /usr/local/async-profiler

CMD ["/bin/parca-agent"]
