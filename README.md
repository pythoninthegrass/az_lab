# az_lab

Azure Cloud sandbox using Terraform, Ansible, and Python (among other languages and tools.)

Takes inspiration from [APT-Lab-Terraform](https://github.com/DefensiveOrigins/APT-Lab-Terraform).

## Installation
* [Install Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-apt?view=azure-cli-latest)
* [Install Terraform](https://learn.hashicorp.com/terraform/getting-started/install.html)

## Setup
### Create Token/Document
* From the [Azure Terraform Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_client_secret.html#creating-a-service-principal-using-the-azure-cli):
    ```bash
    # login
    az login

    # list accounts
    az account list

    # set subscription
    az account set --subscription="<subscription_id>"

    # create service principal
    az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/<subscription_id>" 
    ```
    > This command will output 5 values:
    ```json
    {
        "appId": "00000000-0000-0000-0000-000000000000",
        "displayName": "azure-cli-2017-06-05-10-41-15",
        "name": "http://azure-cli-2017-06-05-10-41-15",
        "password": "0000-0000-0000-0000-000000000000",
        "tenant": "00000000-0000-0000-0000-000000000000"
    }
    ```
    > These values map to the Terraform variables like so:
    >
    > * `appId` is the `client_id` defined above.
    > * `password` is the `client_secret` defined above.
    > * `tenant` is the `tenant_id` defined above.
    >  
* Copy `.env.example` to `.env`
* Edit `.env` and add your token info

## Quickstart
```bash
# navigate to terraform directory
cd ./terraform

# initialize terraform
terraform init -upgrade

# plan terraform
terraform plan -out tfplan

# apply terraform
terraform apply tfplan

# replace ansible_provisioner local-exec
terraform apply -replace="null_resource.ansible_provisioner" -auto-approve

# get public ip address
ip_addr=$(terraform show -json | jq -r '.values.root_module.resources[] | select(.address == "azurerm_linux_virtual_machine.my_terraform_vm").values.public_ip_address')

# copy files to instance
scp ./ansible/playbook.yml ubuntu@${ip_addr}:~

# install ansible and activate virtualenv
poetry install
poetry shell

# install terraform ansible collection
ansible-galaxy collection install -r ./ansible/collections/requirements.yml

# ssh into instance
ssh -i ~/.ssh/id_rsa ubuntu@${ip_addr}

# ping new server
## stray comma is to prevent ansible from reading the ip as a file
ansible all -i "$ip_addr," -m ping -u ubuntu

# run ansible playbook
## -i inventory
## -u user
## -b become
## --tags|--skip-tags <tag>
## -vvv verbose
## -e extra vars
ansible-playbook -i hosts -u ubuntu playbook.yml --skip-tags qa -vvv -e "azure=${ip_addr}"

# disconnect from instance
exit

# destroy terraform
terraform destroy
```

## TODO
* cloud-init
* ansible
  * remote management via ssh (use python to generate new hosts via .env)
* azure
  * windows server
    * domain controller
  * windows client(s)
* [infectionmonkey](https://www.guardicore.com/infectionmonkey/)
* multi-cloud?
  * aws
  * gcp

## Further Reading
[Authenticate Terraform to Azure](https://learn.microsoft.com/en-us/azure/developer/terraform/authenticate-to-azure?tabs=bash#specify-service-principal-credentials-in-a-terraform-provider-block)

[Quickstart: Use Terraform to create a Linux VM](https://learn.microsoft.com/en-us/azure/virtual-machines/linux/quick-create-terraform?tabs=azure-cli)

[Quickstart: Use Terraform to create a Windows VM](https://learn.microsoft.com/en-us/azure/virtual-machines/windows/quick-create-terraform)

[Get Started - Configure Ansible on an Azure VM](https://learn.microsoft.com/en-us/azure/developer/ansible/install-on-linux-vm?tabs=azure-cli#test-ansible-installation)

[How To: Applied Purple Teaming Lab Build on Azure with Terraform (Windows DC, Member, and HELK!) – Black Hills Information Security](https://www.blackhillsinfosec.com/how-to-applied-purple-teaming-lab-build-on-azure-with-terraform/)


