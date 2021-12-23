# Platform-Infrastructure
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

## IP Address Management
### Regional Address Spaces
The following locations have these address ranges
- Building Azure HQ 192.168.1.0/16
- Azure West Europe 10.100.0.0/16
- Azure North Europe 10.100.1.0/16
### VNET Ranges
#### Azure West Europe
- Platform-Hub 10.100.0.0/24
- Platform-Identity 10.100.1.0/24

#### Azure North Europe
- Platform-Hub 10.101.0.0/24
- Platform-Identity 10.101.1.0/24
