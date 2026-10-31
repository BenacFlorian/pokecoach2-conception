# Flyway 11.11.2 — digest resolved at build time via: docker build --pull
FROM flyway/flyway:11.11.2

WORKDIR /flyway

COPY modules ./modules
COPY docker_entrypoint.sh ./
COPY scripts/run-flyway.sh ./scripts/run-flyway.sh

RUN chmod +x docker_entrypoint.sh scripts/run-flyway.sh

ENV POSTGRES_HOST=postgres
ENV POSTGRES_PORT=5432
ENV POSTGRES_DB=pokecoach2

ENTRYPOINT ["bash", "docker_entrypoint.sh"]
