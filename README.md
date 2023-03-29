# UyuniSuite Infra Deploy

## 1. [Helmfile](https://helmfile.readthedocs.io/en/latest/)을 이용하여 UyuniSuite에 필요한 플랫폼을 설치
* gpu-operator. (K8S에서 GPU 사용할 수 있는 시스템)
* ingress-nginx. (K8S Ingress 컨트롤러)
* nfs-provisioner. (nfs 스토리지 프로비저너)
* kafka. (알림 메세지 시스템)
* keycloak. (인증 시스템)
* prometheus. (모니터링 시스템)
* uyuni-suite. (우유니 스위트)

## 2. 디렉토리 구조
```
├── README.md
├── applications  -> 각 플랫폼별 helmfile이 저장되어 있는 폴더
│   ├── uyuni-suite
│   ├── cert-manager
│   ├── efk-stack
│   ├── gpu-operator
│   ├── harbor
│   ├── ingress-nginx
│   ├── kafka
│   ├── keycloak
│   ├── metallb
│   ├── nfs-provisioner
│   └── prometheus
├── environments  -> 환경별로 다른 값을 적용할 수 있는 폴더
│   ├── default
│   ├── katech
│   └── xiilab
└── helmfile.yaml  -> main helmfile 파일
```

## 3. 배포 방법
### 3.1 environments 폴더 안에 있는 default 폴더를 이용하여 새로운 환경 폴더로 copy
```
cp -r environments/default environments/test
```
### 3.2 environments/test/values.yaml 파일을 해당 환경에 맞게 변경
```
vi environments/test/values.yaml
```
```
# 공통 세팅
common:
  ingress:
    # prometheus, keycloak 등 공통 도메인 세팅. default.com으로 세팅하면 
    # 배포 후에 keycloak.default.com와 같이 ingress 가 생성 됨.
    domain: "default.com"

# ingress-nginx 세팅
ingressnginx:
  # ingressnginx servicetype 설정. NodePort 또는 LoadBalancer로 세팅 가능.
  servicetype: NodePort
  # servicetype이 LoadBalancer일 경우, LoadBalancer IP를 세팅 가능
  loadBalancerIP: 192.168.1.210
  # servicetype이 NodePort일 경우 NodePort를 정의.
  nodeports:
    http: 32080
    https: 32443

# nfs-provisioner 세팅
nfsprovisioner:
  # storage class와 연동할 nfs server 정보 입력.
  nfs:
    server: "192.168.56.13"
    path: "/kube_storage"
  # nfs-provisioner를 배포할 노드를 선택할 수 있음. 노드의 라벨 값을 입력. default는 쿠버네티스가 알아서 배포.
  # https://kubernetes.io/ko/docs/tasks/configure-pod-container/assign-pods-nodes/
  # ex)
  # nodeSelector:
  #  kubernetes.io/hostname: gpu-mgmt    
  nodeSelector: {}
  # keycloak, kafka 등 db와 연동할 nfs server에 대한 정보 입력.
  # 업체의 사정에 의해 master node등에 배포해야 될 때 taint가 걸려 있을 수 있음. 이럴 때 tolerations 사용.
  # https://kubernetes.io/ko/docs/concepts/scheduling-eviction/taint-and-toleration
  # ex)
  # tolerations:
  #  - key: "node-role.kubernetes.io/master"
  #    operator: "Exists"
  #    effect: "NoSchedule"  
  tolerations: []

# kafka 세팅.
kafka:
  nodeSelector: {}
  tolerations: []
  # 배포할 kafka zookeeper 서버의 개수. 1, 3 등 홀수로 배포.  
  zookeeper:
    servers: 1
  # 배포할 kafka broker 서버의 개수. 1, 3 등 홀수로 배포.    
  kafka:
    servers: 1

# keycloak 세팅.
keycloak:
  # keyclaok admin password 설정.
  keycloakAdminPassword: keycloak12345
  # keycloak login page 테마 다운로드 url.  
  themeUrl:  https://github.com/xiilab/keycloak-theme-uyuni/releases/download/v1.2.6.1/uyuni-suite-keycloak-theme-v1.2.6.1.jar
  # keycloak node port 지정. default는 service가 NodePort로 설치 됨.
  nodePort: 30090  
  nodeSelector: {}
  tolerations: []

# prometheus 세팅.
prometheus:
  nodeSelector: {}
  tolerations: []

# uyuni 세팅
uyuni:
  # uyuni NodePort 지정. default는 service가 NodePort로 설치 됨.
  nodePort: 30080
  # 설치한 키클락 url 주소 입력. 형식 : http://<node ip>:<NodePort>/auth
  keycloakUrl: http://192.168.56.11:30090/auth
```
### 3.3 helmfile.yaml에 새로 생성한 environments폴더 지정
* environments항목에 생성한 환경폴더 지정.
```
vi helmfile.yaml
```
```
environments:
  default:
    values:
    - environments/default/values.yaml
  # 새로 생성한 test 환경폴더를 지정함.
  # 환경이름을 적고 environments 폴더 안에 경로를 작성해준다.
  test:
    values:
    - environments/test/values.yaml

helmDefaults:
  wait: true
  waitForJobs: true
  timeout: 600

helmfiles:
- path: applications/gpu-operator/helmfile.yaml
  values:
  - {{ toYaml .Values | nindent 4 }}

- path: applications/nfs-provisioner/helmfile.yaml
  values:
  - {{ toYaml .Values | nindent 4 }}

- path: applications/ingress-nginx/helmfile.yaml
  values:
  - {{ toYaml .Values | nindent 4 }}

- path: applications/keycloak/helmfile.yaml
  values:
  - {{ toYaml .Values | nindent 4 }}

- path: applications/prometheus/helmfile.yaml
  values:
  - {{ toYaml .Values | nindent 4 }}

- path: applications/kafka/helmfile.yaml
  values:
  - {{ toYaml .Values | nindent 4 }}

- path: applications/uyuni-suite/helmfile.yaml
  values:
  - {{ toYaml .Values | nindent 4 }}
```
### 3.4 helmfile 명령어를 이용하여 배포, 삭제
#### 3.4.1 모듈 전체 라벨 정의.
* gpu-operator (type=base, app=gpu-operator)
* nfs-provisioner (type=base, app=nfs-provisioner)
* ingress-nginx (type=base, app=ingress-nginx)
* keycloak (type=base, app=keycloak)
* prometheus (type=base, app=prometheus)
* kafka (type=base, app=kafka)
* uyuni-suite (type=app, app=uyuni-suite)
 
#### 3.4.2 플랫폼 전체 배포.
#### 3.4.2.1 우유니에 필요한 플랫폼 전체 배포(type=base로 라벨이 붙어 있는 모듈)
```
helmfile --environment test -l type=base sync
```
#### 3.4.2.2 배포가 잘 되었으면 keycloak url 확인.
```
kubectl get svc -n keycloak
```
keycloak-http service의 80포트에 해당하는 nodePort 확인 
```
NAME                           TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                                      AGE
keycloak-headless              ClusterIP   None            <none>        80/TCP                                       5m9s
keycloak-http                  NodePort    10.233.23.138   <none>        80:30090/TCP,8443:32052/TCP,9990:31400/TCP   5m9s
keycloak-postgresql            ClusterIP   10.233.23.153   <none>        5432/TCP                                     5m9s
keycloak-postgresql-headless   ClusterIP   None            <none>        5432/TCP                                     5m9s
```
#### 3.4.2.3 environments/test/values.yaml 파일에서 uyuni부분을 해당 환경에 맞게 변경
```
vi environments/test/values.yaml
```
* keycloak url 부분을 해당 서버 ip에 맞게 수정
```
# uyuni 세팅
uyuni:
  # uyuni NodePort 지정. default는 service가 NodePort로 설치 됨.
  nodePort: 30080
  # 설치한 키클락 url 주소 입력. 형식 : http://<node ip>:<NodePort>/auth
  keycloakUrl: http://192.168.56.11:30090/auth
```
#### 3.4.2.4 kube-config 파일 copy
```
cp ~/.kube/config applications/uyuni-suite/uyuni-suite/config
```
* config 파일 내 server 항목에 반드시 node ip를 입력
```
KQ1VzPQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg==
    #nodeip 입력 127.0.0.1 이 아님
    server: https://127.0.0.1:6443 
  name: cluster.local
contexts:
- context:
    cluster: cluster.local
    user: kubernetes-admin
  name: kubernetes-admin@cluster.local
current-context: kubernetes-admin@cluster.local
kind: Config
preferences: {}
users:
- name: kubernetes-admin
  user:
```
#### 3.4.2.5 uyuni-suite 배포(type=app로 라벨이 붙어 있음.)
```
helmfile --environment test -l type=app sync
```
#### 3.4.2.5 접속 정보 확인
```
kubectl get svc -n uyuni-suite
```
* uyuni-suite-frontend service의 80포트에 해당하는 NodePort로 접속.
```
NAME                   TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
mariadb                ClusterIP   10.233.39.218   <none>        3306/TCP       37m
uyuni-suite-batch      ClusterIP   10.233.22.214   <none>        8080/TCP       37m
uyuni-suite-core       ClusterIP   10.233.45.123   <none>        8080/TCP       37m
uyuni-suite-frontend   NodePort    10.233.21.192   <none>        80:30080/TCP   37m
uyuni-suite-noti       ClusterIP   10.233.29.108   <none>        8080/TCP       37m
```


## 4. 명령어 모음
### 4.1. 우유니에 필요한 플랫폼 전체 배포, 삭제 명령어
#### 4.1.1 우유니에 필요한 플랫폼 전체 설치 명령어
* label이 type=base인 항목들 전체 설치.
* helmfile --environment <helmfile.yaml에 정의한 환경변수 이름> -l type=base sync
```sh
helmfile --environment test -l type=base sync
```

### 4.1.2 우유니에 필요한 플랫폼 전체 삭제 명렁어
helmfile --environment <helmfile.yaml에 정의한 환경변수 이름> -l type=base destroy
```
helmfile --environment test -l type=base destroy
```

### 4.2. 우유니 배포, 삭제 명령어
#### 4.2.1 우유니 설치 명령어
* label이 type=app인 항목 설치.
* helmfile --environment <helmfile.yaml에 정의한 환경변수 이름> -l type=app sync
```sh
helmfile --environment test -l type=app sync
```

### 4.2.2 우유니 삭제 명렁어
helmfile --environment <helmfile.yaml에 정의한 환경변수 이름> -l type=app destroy
```
helmfile --environment test -l type=app destroy
```

### 4.3. 모듈 개별로 배포 및 삭제 명령어
#### 4.3.1 모듈 개별로 배포 명령어
helmfile --environment <helmfile.yaml에 정의한 환경변수 이름> -l app=<app 이름> sync
```
helmfile --environment test -l app=ingress-nginx sync
```

#### 4.3.2 모듈 개별로 삭제 명령어
helmfile --environment <helmfile.yaml에 정의한 환경변수 이름> -l app=<app 이름> destroy
```
helmfile --environment xiilab -l app=ingress-nginx destroy
```
