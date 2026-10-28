# AWS Load Balancer Controller manifests

The controller manifest is pinned to AWS Load Balancer Controller `v2.14.1`, downloaded from its [official release](https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases/tag/v2.14.1). The matching `IngressClass` is included in `ingressclass.yaml`.

Before applying the manifests:

1. Install cert-manager. The controller's webhook certificate resources depend on it.
2. Create and attach the controller IAM policy and role, then create the EKS Pod Identity association for `kube-system/aws-load-balancer-controller`.
3. Replace `REPLACE_WITH_EKS_VPC_ID` in `v2_14_1_full.yaml` with the VPC ID of the EKS cluster. The region and cluster name are already set for this lab.

Apply this directory from the bastion after those prerequisites are ready:

```bash
kubectl apply -f platform/aws-load-balancer-controller/
```

The manifest is adapted from the AWS Load Balancer Controller project and retains its upstream license header and release contents.
