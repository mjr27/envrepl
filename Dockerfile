FROM nimlang/nim:1.2.6 as BUILD

RUN apt-get update && apt-get install -y musl-tools
WORKDIR /app

COPY *.nimble ./
RUN nimble install -d -y

COPY src ./src
RUN nimble static -y

FROM scratch
COPY --from=BUILD /app/envrepl /envrepl
ENTRYPOINT [ "/envrepl" ]