FROM confluentinc/cp-kafka-connect:7.5.0 AS confluent-source
FROM debezium/connect:2.7.3.Final AS debezium-source

FROM quay.io/strimzi/kafka:1.0.1-kafka-4.2.0

USER root

# Create plugin directory
RUN mkdir -p /opt/kafka/plugins && \
    chown -R 1001:0 /opt/kafka/plugins

# Copy Debezium plugins
COPY --from=debezium-source --chown=1001:0 /kafka/connect/ /opt/kafka/plugins/

# Copy Confluent Avro serdes
COPY --from=confluent-source --chown=1001:0 /usr/share/java/kafka-serde-tools/ /opt/kafka/plugins/confluent-avro/

USER kafka

# Download and set up OpenTelemetry Java Agent
ADD --chown=1001:0 https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/download/v2.27.0/opentelemetry-javaagent.jar /otel/otel-javaagent.jar


# ENV KAFKA_OPTS="-javaagent:/otel/otel-javaagent.jar"


