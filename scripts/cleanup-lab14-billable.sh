#!/usr/bin/env bash
set -e

. "$HOME/xlabs-cloud/aws-labs/compute/bastion-values.env"
ssh -o ConnectTimeout=10 -i "$JUMP_HOST_PRIVATE_KEY_PATH" \
  "ec2-user@$JUMP_HOST_PUBLIC_IP" \
  'export PATH="$HOME/bin:$PATH"; kubectl delete namespace news-scraper --ignore-not-found=true --wait=true'

ROLE_NAME=xlabs-news-scraper-lbc-role
POLICY_NAME=xlabs-news-scraper-lbc-policy
ROLE_ARN=$(aws iam get-role --role-name "$ROLE_NAME" --profile xlabs-aws --query 'Role.Arn' --output text 2>/dev/null || true)
ROLE_TAG=$(aws iam list-role-tags --role-name "$ROLE_NAME" --profile xlabs-aws --query "length(Tags[?Key=='XLabsLab' && Value=='cloud00-14'])" --output text 2>/dev/null || true)
POLICY_ARN=$(aws iam list-policies --scope Local --profile xlabs-aws --query "Policies[?PolicyName=='$POLICY_NAME'].Arn | [0]" --output text)

if [ "$ROLE_TAG" = "1" ]; then
  if [ -n "$ROLE_ARN" ] && [ "$ROLE_ARN" != "None" ] && \
    aws eks describe-cluster --name xlabs-news-scraper-eks --profile xlabs-aws --region us-east-1 >/dev/null 2>&1; then
    ASSOCIATION_IDS=$(aws eks list-pod-identity-associations \
      --cluster-name xlabs-news-scraper-eks \
      --namespace kube-system \
      --service-account aws-load-balancer-controller \
      --profile xlabs-aws \
      --region us-east-1 \
      --query "associations[?roleArn=='$ROLE_ARN'].associationId" \
      --output text)
    if [ -n "$ASSOCIATION_IDS" ] && [ "$ASSOCIATION_IDS" != "None" ]; then
      for ASSOCIATION_ID in $ASSOCIATION_IDS; do
        aws eks delete-pod-identity-association \
          --cluster-name xlabs-news-scraper-eks \
          --association-id "$ASSOCIATION_ID" \
          --profile xlabs-aws \
          --region us-east-1
      done
    fi
  fi

  ATTACHED_POLICIES=$(aws iam list-attached-role-policies \
    --role-name "$ROLE_NAME" --profile xlabs-aws \
    --query 'AttachedPolicies[].PolicyArn' --output text)
  if [ -n "$ATTACHED_POLICIES" ] && [ "$ATTACHED_POLICIES" != "None" ]; then
    for ATTACHED_POLICY in $ATTACHED_POLICIES; do
      aws iam detach-role-policy --role-name "$ROLE_NAME" \
        --policy-arn "$ATTACHED_POLICY" --profile xlabs-aws
    done
  fi

  INLINE_POLICIES=$(aws iam list-role-policies \
    --role-name "$ROLE_NAME" --profile xlabs-aws \
    --query 'PolicyNames[]' --output text)
  if [ -n "$INLINE_POLICIES" ] && [ "$INLINE_POLICIES" != "None" ]; then
    for INLINE_POLICY in $INLINE_POLICIES; do
      aws iam delete-role-policy --role-name "$ROLE_NAME" \
        --policy-name "$INLINE_POLICY" --profile xlabs-aws
    done
  fi
  aws iam delete-role --role-name "$ROLE_NAME" --profile xlabs-aws
fi

if [ -n "$POLICY_ARN" ] && [ "$POLICY_ARN" != "None" ]; then
  POLICY_TAG=$(aws iam list-policy-tags --policy-arn "$POLICY_ARN" \
    --profile xlabs-aws \
    --query "length(Tags[?Key=='XLabsLab' && Value=='cloud00-14'])" \
    --output text)
  if [ "$POLICY_TAG" = "1" ]; then
    aws iam delete-policy --policy-arn "$POLICY_ARN" --profile xlabs-aws
  fi
fi

bash "$HOME/xlabs-cloud/aws-labs/scripts/cleanup-lab13-billable.sh"
