# AWS EKS

It creates:
* **VPC**
* **AWS EKS cluster**
  * **aws loadbalancer controller**: listens for service type `LoadBalancer` and creates ALB. Used to create ALB on top on nginx controller
  * **vpc cni**: created via addon, used to provide networking via AWS subnet
  * **cert manager**: automatically creates certificates via Let's Encrypt
  * **ebs csi driver**: manages PVC for EBS volume
  * **efs csi driver**: manages PVC for EFS volume
  * **external dns**: listens `ingress` and create Route53 records pointing on nginx controller ALB
  * **fluent bit**: forward k8s logs to cloudwatch
  * **nginx ingress controller**: redirect traffic to the right service
  * **metrics-server**: collects CPU/memory metrics used by pod HPA
  * **prometheus**: monitors the Kubernetes cluster

### How use kubectl ?

Check pipeline access job

```bash
# If needed to assume role
# export AWS_ROLE_ARN="arn:aws:iam::xxxxxxxx:role/admin"
# aws sts assume-role --role-arn $AWS_ROLE_ARN --role-session-name admin | jq -r '.Credentials | "export AWS_ACCESS_KEY_ID=\(.AccessKeyId); export AWS_SECRET_ACCESS_KEY=\(.SecretAccessKey) export AWS_SESSION_TOKEN=\(.SessionToken)"' > /tmp/awslogin
# source /tmp/awslogin

aws eks --region ${AWS_DEFAULT_REGION} update-kubeconfig  --name ${CLUSTER_NAME}
```

### How to access the ingress-controller ?

via the AWS ALB
