# Elasticsearch Service

This repository contains our elasticsearch dockerfile.


## Building the dockerfile

A dockerfile is provided to make the elasticsearch-service run in a container.
The container contains the elasticsearch-service itself, the jaeger agent that handle traces and monit.
To build the container you must provides the following build-args:

- `elasticsearch_service_git_tag`: the git tag of elasticsearch-service repository (<https://github.com/cloudtrust/elasticsearch-service>).
- `elasticsearch_bridge_release`: the elasticsearch-service release archive, e.g. <https://github.com/cloudtrust/elasticsearch-service/releases/download/1.0/v1.0.tar.gz>. It can be found [here](https://github.com/cloudtrust/elasticsearch-service/releases).
- `jaeger_release`: the jaeger release archive, e.g. <https://github.com/cloudtrust/jaeger/releases/download/v1.3.0/v1.3.0.tar.gz>. It can be found [here](https://github.com/cloudtrust/jaeger/releases).
- `config_repo`: the repository containing the configuration, e.g. <https://github.com/cloudtrust/dev-config.git>.
- `config_git_tag`: the git tag of config repository.

Then you can build the image.

```bash
mkdir build_context
cp dockerfiles/cloudtrust-elasticsearch-service.dockerfile build_context/
cd build_context

docker build --build-arg elasticsearch_service_git_tag=<elasticsearch_service_git_tag> --build-arg elasticsearch_bridge_release=<elasticsearch_bridge_release> --build-arg jaeger_release=<jaeger_release> --build-arg config_git_tag=<config_git_tag> --build-arg config_repo=<config_repo> -t cloudtrust-elasticsearch-service -f cloudtrust-elasticsearch.dockerfile .
```

## Configuration

Configuration is done with a YAML file, e.g. ```./configs/flakid.yml```.
Default configurations are provided, that is if an entry is not present in the configuration file, it will be set to its default value.

The documentation for the [Redis](https://cloudtrust.github.io/doc/chapter-godevel/logging.html), [Influx](https://cloudtrust.github.io/doc/chapter-godevel/instrumenting.html), [Sentry](https://cloudtrust.github.io/doc/chapter-godevel/tracking.html), [Jaeger](https://cloudtrust.github.io/doc/chapter-godevel/tracing.html) and [Debug](https://cloudtrust.github.io/doc/chapter-godevel/debugging.html) configuration are common to all microservices and is provided in the Cloudtrust Gitbook.

The configurations specific to the flaki-service are described in the next sections.


## Running keycloak

Depending on the config repo, the container could expect some names to be reachable. Refer to the specifics of the configuration repo.

An example run command should look like

```Bash
#Run the container
docker run --rm -it --net=ct_bridge --tmpfs /tmp --tmpfs /run -v /sys/fs/cgroup:/sys/fs/cgroup:ro --name elasticsearch-service -p 8080:80 cloudtrust-elasticsearch-service
```

