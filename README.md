# TERRAFORM EXAMPLE WITH REMOTE BACKEND / LOCKING

## Bootstrap S3 Bucket for Statefile:
```sh
terraform init
terraform apply
```

```
terraform destroy
```

### deploy with variable values
variables are set in the *.tfvars files

```sh
terraform apply -var-file="customvariables.tfvars"
```

### variante variables set values in comandline
```sh
export TF_VAR_bootstrap_bucket_name="misaslockingbucket2" \
terraform apply"
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

