# az-data-services-demo

In this demo a solution named **DataBoss** will be used to connect and apply Azure data services.

```
cp templates/template.tf .auto.tfvars
```

```sh
dig +short myip.opendns.com @resolver1.opendns.com
```

```sh
terraform init
terraform apply -auto-approve
```

**🛑👉 You'll have to manually approve the managed private endpoints created by ADF.**
 

```sh
bash scripts/uploadFilesToDataLake.sh

bash scripts/uploadFilesToExternalStorage.sh
bash scripts/createExternalPipeline.sh
```

```sh
az datafactory pipeline create-run --resource-group rg-databoss \
    --name Adfv2CopyExertnalFileToLake --factory-name adf-databoss

az datafactory pipeline-run show --resource-group ADFQuickStartRG \
    --factory-name ADFTutorialFactory --run-id 00000000-0000-0000-0000-000000000000
```


```sh
terraform -chdir="databricks" init
terraform -chdir="databricks" apply -auto-approve
```


- [] Private endpoints
- [] Managed private network
- [] Consume IP addresses
- [] Internal runtime
- [] Code repository
- [] AD permissions

Enable IR interactive authoring
Approve the private link



https://learn.microsoft.com/en-us/azure/data-factory/managed-virtual-network-private-endpoint#managed-private-endpoints
https://learn.microsoft.com/en-us/azure/data-factory/concepts-integration-runtime