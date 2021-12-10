# Platform
This repository contains all of the necessary infrastucture-as-code to deploy the Azure Platform resources. This will deploy resources such as:
- Hub VNET
- Identity VNET
- VPN Gateway
- Domain Controllers
- Log Analytics Workspace
- Azure Automation Account
- Network Security Group Flow Logs Storage Account
- Azure Cloud Shell Storage Account
- Terraform State Storage Account
- Private DNS Zones
- Azure Policy Definitions

## Resource Group Naming Convention
The plaform resource groups will be called the following:

- platform-identity-westeurope
- platform-connectivity-westeurope
- platform-management-westeurope
