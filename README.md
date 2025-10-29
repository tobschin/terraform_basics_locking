# TERRAFORM EXAMPLE WITH REMOTE BACKEND / LOCKING

## Bootstrap S3 Bucket for Statefile:
```sh
terraform init
terraform apply
```

```
terraform destroy
```


## Deploy Lambda Function
```sh
cd lambda
terraform init
terraform apply
```


```
terraform destroy
```

### Doku
https://developer.hashicorp.com/terraform/tutorials/aws-get-started/aws-create
https://developer.hashicorp.com/terraform/language/backend/s3#use_lockfile

