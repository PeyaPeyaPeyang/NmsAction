FROM debian:bookworm-slim

# openjdk-8-jdk は Stable ではサポートされないので sid から取得する
RUN echo "deb http://deb.debian.org/debian/ sid main" | tee -a /etc/apt/sources.list
RUN apt update && apt install -y git wget maven openjdk-17-jdk openjdk-8-jdk

COPY entrypoint.sh entrypoint.sh
RUN chmod +x entrypoint.sh
ENV M2_HOME=/usr/share/maven
ENTRYPOINT ["/entrypoint.sh"]
