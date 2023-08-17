terraform {
  required_version = ">=1.0.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.68.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "projeto-terraform-resource-group"
    storage_account_name = "storageaccounttf2112"
    container_name       = "projeto-terraform-container"
    key                  = "azure-vm-provisioners/terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

data "terraform_remote_state" "vnet" {
  backend = "azurerm"
  config = {
    resource_group_name  = "projeto-terraform-resource-group"
    storage_account_name = "storageaccounttf2112"
    container_name       = "projeto-terraform-container"
    key                  = "azure-vnet/terraform.tfstate"
  }
}

# para acessar a vm pelo terminal: ssh -i nomeDoArquivoChavePrivada nomeUsuarioQueCriamos@IP
