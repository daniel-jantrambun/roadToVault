# Create Kubernetes Cluster With Terraform

The goal of this article is to show how to create a GKE cluster with [HashiCorp Terraform](https://www.terraform.io/). This cluster will be used later to install our vault.

**Requirements:**

Having an active GCP account, linked to a billing account.
Having enabled the following API:

- [compute api)](https://console.cloud.google.com/apis/library/compute.googleapis.com)
- [storage api](https://console.cloud.google.com/apis/library/storage.googleapis.com)
- [container api](https://console.cloud.google.com/apis/library/container.googleapis.com)

## GCP configuration

### terraform service account

Create a service account terraform in GCP IAM with roles:

- Compute Admin
- Compute Network Admin
- Kubernetes Engine Admin
- Service Account User
- Storage Admin

### service account key

In `Service Account` menu, create a new json `key` and store it in the terraform folder of your project.

### Google Storage bucket

The `terraform state` file will be stored in a `GCS bucket` backend

On GCP console, create a `bucket` (you can name as you want but remember that bucket names are unique in GCP). We only need a regional bucket.

Choose `standard` as storage default class.

## Initiate terraform

Make sure your gcloud is connected with command:

```bash
gcloud auth application-default login
```

Once you’re connected, go on the terraform directory of your project, and initialise your terraform project:

```bash
terraform init -backend-config="bucket=<your_bucket_name"
```

In the previously created bucket, there now should be a folder state that contains a file `default.tfstate`

## Create Cluster

In the terraform.tfvars file, replace the values of variables:

- terraform_json_key
- project_id
- terraform_bucket_name
- with your own values.

We are now ready to create the cluster. Check that our terraform configuration is correct:

```bash
terraform plan
```

If everything is ok, you can create the cluster by applying your terraform plan:

```bash
terraform apply
```

The installation should take a few minutes.

At the end, you should have the following line:

`Apply complete! Resources: 8 added, 0 changed, 0 destroyed.`

and the output variables should be printed.

This cluster will be used to install our vault. 🙂

## Clean up

To avoid unusefull billing, we can destroy the cluster

```bash
terraform destroy
```
