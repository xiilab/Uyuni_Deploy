
# uyuni-suite-helm

Uyuni Suite 을 설치하기 워한 Helm 파일 입니다.




## 설정

value.yaml 파일을 통하여 설치할 서버 환경에 맞추어서 설치 진행


```yaml
uyuni:
  common:
    nameOverride: ""
    fullnameOverride: ""

    serviceAccount:
      # Specifies whether a service account should be created
      create: false
      # Annotations to add to the service account
      annotations: { }
      # The name of the service account to use.
      # If not set and create is true, a name is generated using the fullname template
      name: ""

    # 호스트 네임이 있을때 적용
    ingress:
      # true : 호스트 네임 / false : 아이피로 접속
      enabled: false
      className: "nginx"
      annotations: { }
      # kubernetes.io/ingress.class: nginx.conf
      # kubernetes.io/tls-acme: "true"
      hosts:
        - host: test.uyuni-suite.xiilab.com
          paths: []
      tls: [ ]
      #  - secretName: chart-example-tls
      #    hosts:
      #      - chart-example.local

    # 접속 포트 설정
    service:
      type: NodePort
      nodePort: "30100"
   
    # 키클락 설정
    keycloak:
      url: "http://192.168.1.235:30051/auth"
      # 폐쇄망에서 키클락 호스트가 있을경우에 사용
      hostAliases: []




  # 프론트엔드 설정
  frontend:
    replicaCount: 1

    image:
      repository: xiilab/uyuni-suite-frontend
      pullPolicy: IfNotPresent
      # Overrides the image tag whose default is the chart appVersion.
      tag: "0.4.38-stag"

    imagePullSecrets: []
    podAnnotations: {}
    podSecurityContext: {}
    # fsGroup: 2000
    securityContext: {}
```

## Deployment

파일 설정후 다음 명령어를 통하여 설치 진행

```bash
helm install -f <values.yaml경로> <helm 이름 > <helm chart 경로> -n <네임스페이스>
```

```bash
helm upgrade -f values.yaml uyuni-suite . -n uyuni-test
```
## Installation

Install my-project with npm

```bash
export NODE_PORT=$(kubectl get --namespace uyuni-test -o jsonpath="{.spec.ports[0].nodePort}" services uyuni-suite-frontend)
export NODE_IP=$(kubectl get nodes --namespace uyuni-test -o jsonpath="{.items[0].status.addresses[0].address}")
echo http://$NODE_IP:$NODE_PORT
http://192.168.1.154:30100
```
    
