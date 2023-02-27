# UyuniSuite Infra Deploy

[Helmfile](https://helmfile.readthedocs.io/en/latest/)을 이용하여 UyuniSuite에 필요한 플랫폼을 설치
* gpu-operator (type: infra)
* ingress-nginx (type: infra)
* nfs-provisioner (type: storage)
* kafka (type: app)
* keycloak (type: app)
* prometheus (type: app)

## 디렉토리 구조
```
├── README.md
├── applications  -> 각 플랫폼별 helmfile이 저장되어 있는 폴더
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

## 환경설정 방법
1. environments 폴더 -> 각 환경별 폴더를 생성해주고 values.yaml 파일을 생성.
2. 
```
common:
  ingress:
    domain: "xiilab.com"

nfsprovisioner:
  nfs:
    server: "192.168.2.27"
    path: "/kube_storage"

harbor:
  harborAdminPassword: password

keycloak:
  keycloakAdminPassword: password
```

2. root폴더에 있는 helmfile.yaml의 environments: 부분에 생성한 values.yaml 경로를 추가

```
environments:
  default:
    values:
    - environments/default/values.yaml
  develop:
  production:
  katech:
    values:
    - environments/katech/values.yaml
  xiilab:
    values:
    - environments/xiilab/values.yaml
```


## 명령어
### 인프라 설치(root helmfile.yaml이 있는곳에서 실행)
#### helmfile을 이용하여 인프라 설치및 제거

# 설치
helmfile --environment <helmfile.yaml에 정의한 환경변수 이름> sync
- ex) `helmfile --environment xiilab sync`

- metalib 비활성화

```sh
helmfile --environment itmaya -l type=base sync
```

# 제거
helmfile --environment <helmfile.yaml에 정의한 환경변수 이름> destroy
- ex) `helmfile --environment xiilab destroy`


#### type별로 설치 및 제거
```
# 설치
helmfile --environment <helmfile.yaml에 정의한 환경변수 이름> -l type=<type 이름> sync 
helmfile --environment xiilab -l type=infra sync

# 제거
helmfile --environment <helmfile.yaml에 정의한 환경변수 이름> -l type=<type 이름> destroy 
helmfile --environment xiilab -l type=infra destroy
```

#### 하나씩 설치 및 제거
```
# 설치
helmfile --environment <helmfile.yaml에 정의한 환경변수 이름> -l app=<app 이름> sync 
helmfile --environment xiilab -l app=ingress-nginx sync

# 제거
helmfile --environment <helmfile.yaml에 정의한 환경변수 이름> -l app=<app 이름> destroy 
helmfile --environment xiilab -l app=ingress-nginx destroy
```
