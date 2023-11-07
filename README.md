# Druid on K8S

## Druid Operator
- https://github.com/datainfrahq/druid-operator

### Deploy Druid Operator
```shell
$ git clone \
       --branch druid-operator-0.0.9 \
       https://github.com/datainfrahq/druid-operator.git
    
# It is better to modify value.yaml than to overwrite the value with `--set`.
$ helm install -n druid-demo \
       --set env.WATCH_NAMESPACE=druid-demo \
       --set image.tag=0.0.9 \
       --set resources.limits.cpu=100m \
       --set resources.limits.memory=128Mi \
       --set resources.requests.cpu=100m \
       --set resources.requests.memory=128Mi \
       druid-operator druid-operator/chart
```

## Druid Cluster
- component
  - druid
  - [turnilo](https://github.com/allegro/turnilo)
  - nginx proxy : basic-auth reverse proxy
    - htpasswd(id/pw) : `druid:druid` (default)
    - port
      - 8081 : router ui
      - 8082 : broker
      - 8083 : turnilo

### Deploy Druid Cluster
```shell
$ helm install -n druid-demo \
       --set zookeeper.host=tiny-cluster-zk \
       -f ./chart/values/tiny.yaml \
       druid-cluster ./chart
```

## License
```
Copyright (c) 2023-present NAVER Corp.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
