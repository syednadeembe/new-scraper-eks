# News Scraper for Amazon EKS

This repository packages the News Scraper for the Lab 13 EKS cluster. Its application source is adapted from [syednadeembe/news-scraper](https://github.com/syednadeembe/news-scraper); that repository remains unchanged. This EKS version uses plain Kubernetes manifests.

## Request flow

```text
Browser ── HTTP ──> AWS ALB Ingress
                       ├── /, frontend assets ──> frontend ClusterIP Service ──> Nginx static-file Pod
                       ├── /search ─────────────> backend ClusterIP Service ──> FastAPI Pod
                       └── /history ────────────> backend ClusterIP Service ──> FastAPI Pod
                                                                           └──> mongo ClusterIP Service ──> MongoDB Pod
```

The browser uses same-origin relative paths for the API. Nginx only serves the static frontend; it is not an API proxy. MongoDB is internal and stores its data on the Lab 10 `news-scraper-gp3` StorageClass through the Lab 13 EBS CSI driver.

## Prerequisites

- The EKS cluster, worker nodes, EBS CSI driver, and EKS Pod Identity Agent from Labs 12–13 are available.
- Install cert-manager, create the controller IAM role and Pod Identity association, and apply the pinned controller manifests in `platform/aws-load-balancer-controller/` before applying `k8s/05-ingress.yaml`. See that directory's README for the short setup sequence.
- The public subnets are tagged for ALB discovery and span at least two Availability Zones.
- `news-scraper-gp3` StorageClass exists.
- The two public Docker Hub images below have been built and pushed.

## Build and publish images

Run from the repository root on a machine with Docker:

```bash
docker build --platform linux/amd64 -t xlabsimages/news-scraper-backend:v2 ./backend
docker push xlabsimages/news-scraper-backend:v2
docker build --platform linux/amd64 -t xlabsimages/news-scraper-frontend:v2 -f frontend/Dockerfile .
docker push xlabsimages/news-scraper-frontend:v2
```

The backend image includes the FastAPI `/healthz` endpoint used by Kubernetes probes and the ALB target health check.

## Deploy from the bastion

Apply in order after the controller is ready:

```bash
kubectl apply -f k8s/00-namespace.yaml
kubectl apply -f k8s/01-mongo-pvc.yaml
kubectl apply -f k8s/02-mongo.yaml
kubectl apply -f k8s/03-backend.yaml
kubectl apply -f k8s/04-frontend.yaml
kubectl apply -f k8s/05-ingress.yaml
```

Check rollout and routing:

```bash
kubectl get pods,services,endpoints,pvc -n news-scraper
kubectl get ingress -n news-scraper
```

Open the Ingress address in a browser. The ALB sends `/search` and `/history` requests directly to FastAPI; FastAPI reaches MongoDB through the internal `mongo` Service.

## Remove the application

Delete the Ingress first so the Load Balancer Controller can remove its ALB. Then remove the namespace:

```bash
kubectl delete -f k8s/05-ingress.yaml
kubectl wait --for=delete ingress/news-scraper -n news-scraper --timeout=10m
kubectl delete namespace news-scraper
```

The `news-scraper-gp3` StorageClass uses a Retain reclaim policy, so inspect and remove any retained EBS volume separately when the lab's cleanup instructions call for it.
