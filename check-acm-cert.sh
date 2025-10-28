set -euo pipefail
ACM_CERT_ARN="arn:aws:acm:us-east-1:383585068161:certificate/d8c0c2b4-ba47-47ad-a545-bf522eed8e7b"
AWS_REGION="us-east-1"
NS=ingress-nginx
SVC=ingress-nginx-controller
SVC_ARN=$(kubectl -n "$NS" get svc "$SVC" -o jsonpath='{.metadata.annotations.service\.beta\.kubernetes\.io/aws-load-balancer-ssl-cert}')
test -n "${SVC_ARN:-}" || { echo "::error:: Service missing ssl-cert annotation"; exit 1; }
[ "$SVC_ARN" = "$ACM_CERT_ARN" ] || { echo "::error:: Annotation ($SVC_ARN) != expected ($ACM_CERT_ARN)"; exit 1; }

LB_DNS=$(kubectl -n "$NS" get svc "$SVC" -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
test -n "${LB_DNS:-}" || { echo "::error:: LB hostname not ready"; exit 1; }
LB_ARN=$(aws elbv2 describe-load-balancers --region "$AWS_REGION" \
  --query "LoadBalancers[?DNSName=='$LB_DNS'].LoadBalancerArn" --output text)
LISTENER_CERTS=$(aws elbv2 describe-listeners --region "$AWS_REGION" \
  --load-balancer-arn "$LB_ARN" --query "Listeners[?Port==\`443\`].Certificates[].CertificateArn" --output text)
echo "$LISTENER_CERTS" | grep -q "$ACM_CERT_ARN" || { echo "::error:: NLB 443 does not reference ACM_CERT_ARN"; exit 1; }
