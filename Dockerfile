ARG ENVOY_VERSION
# Taken from emissary-ingress:docker/base-envoy.docker + replacing envoy-0 by envoy-full-0
FROM emissaryingress/base-envoy:envoy-full-0.bbda92fc3e3d430bd2114aa3458d3191205c9c0e.opt as emissary_envoy

FROM ubuntu:23.04 AS perf_data_converter

RUN apt update && apt install -y npm g++ git libelf-dev libcap-dev
RUN npm install -g @bazel/bazelisk

RUN git clone https://github.com/google/perf_data_converter.git /usr/src/perf_data_converter
WORKDIR /usr/src/perf_data_converter

RUN bazel build src:perf_to_profile
RUN cp bazel-bin/src/perf_to_profile /usr/bin/.

FROM golang:latest
COPY --from=perf_data_converter /usr/lib/x86_64-linux-gnu/libelf.so /usr/lib/x86_64-linux-gnu/libelf.so
COPY --from=perf_data_converter /usr/bin/perf_to_profile /usr/bin/perf_to_profile
COPY --from=emissary_envoy /usr/local/bin/envoy-static /usr/local/bin/envoy

RUN apt update && apt install -y graphviz
RUN go install github.com/google/pprof@latest

ENTRYPOINT ["pprof", "-http=0.0.0.0:8888", "/usr/local/bin/envoy"]
