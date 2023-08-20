# We strongly recommend using the required_providers block to set the here
# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
    backend "azurerm" {
      resource_group_name  = "rg-jenkins-ci"
      storage_account_name = "jenkinsac23"
      container_name       = "tfstate"
      key                  = "terraform.tfstate"
  }
}


# Configure the Microsoft Azure Provider
provider "azurerm" {
    features {}
}

resource "azurerm_resource_group" "rg" {
    name     = "tf-demo-rg-ci"
    location = "centralindia"
}

resource "azurerm_network_security_group" "nsg"{
    name                = "tf-demo-nsg-ci"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_rule" "testrules" {
    for_each                    = local.nsgrules 
    name                        = each.key
    direction                   = each.value.direction
    access                      = each.value.access
    priority                    = each.value.priority
    protocol                    = each.value.protocol
    source_port_range           = each.value.source_port_range
    destination_port_range      = each.value.destination_port_range
    source_address_prefix       = each.value.source_address_prefix
    destination_address_prefix  = each.value.destination_address_prefix
    resource_group_name         = azurerm_resource_group.rg.name
    network_security_group_name = azurerm_network_security_group.nsg.name
}

resource "azurerm_virtual_network" "vnet" {
    depends_on          = [azurerm_resource_group.rg]
    name                = "tf-demo-vnet-ci"
    address_space       = ["10.5.104.0/22"]
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
    depends_on                 = [azurerm_virtual_network.vnet, azurerm_network_security_group.nsg]
    name                       = "subnet-vm-ci"
    resource_group_name        = azurerm_resource_group.rg.name
    virtual_network_name       = azurerm_virtual_network.vnet.name
    address_prefixes           = ["10.5.104.0/24"]
}

resource azurerm_subnet_network_security_group_association "nsgassociation" {
    subnet_id                 = azurerm_subnet.subnet.id
    network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_public_ip" "publicip" {
    depends_on                = [azurerm_subnet.subnet]
    name = "tf-demo-vm-ci-pip"
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    allocation_method = "Static"
    sku = "Standard"
}

resource "azurerm_network_interface" "nic" {
    depends_on                = [azurerm_subnet.subnet]
    name                      = "tf-demo-vm-ci-nic"
    location                  = azurerm_resource_group.rg.location
    resource_group_name       = azurerm_resource_group.rg.name

    ip_configuration {
      name                          = "internal"
      subnet_id                     = azurerm_subnet.subnet.id
      private_ip_address_allocation = "Dynamic"
      public_ip_address_id = azurerm_public_ip.publicip.id
    }
    
}

resource "azurerm_virtual_machine_extension" "extension" {
    depends_on = [azurerm_virtual_machine.vm]
    name = "tf-demo-vm-ci-ext"
    virtual_machine_id = azurerm_virtual_machine.vm.id
    publisher = "Microsoft.Azure.Extensions"
    type = "CustomScript"
    type_handler_version = "2.1"
    settings = <<SETTINGS
    {
        "commandToExecute": "sudo apt-get update && sudo apt-get install -y nginx && sudo service nginx start"
    }
    SETTINGS
}

resource "azurerm_storage_account" "storage" {
    name = "tfdemostorageci02"
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location
    account_tier = "Standard"
    account_replication_type = "LRS"
}

resource "azure_storage_Account_container" "container" {
    name = "tf-demo-container-ci"
    storage_account_name = azurerm_storage_account.storage.name
    container_access_type = "private"
}

resource "azurerm_virtual_machine" "vm" {
    depends_on = [azurerm_subnet.subnet]
    name = "tf-demo-vm-ci"
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    network_interface_ids = [azurerm_network_interface.nic.id]
    vm_size = "Standard_D2AS_v5"
    delete_os_disk_on_termination = true
    delete_data_disks_on_termination = true
    storage_image_reference {
        publisher = "Canonical"
        offer = "UbuntuServer"
        sku = "20.04-LTS"
        version = "latest"
    }
    storage_os_disk {
        name = "tf_demo_vm_ci_osdisk"
        caching = "ReadWrite"
        create_option = "FromImage"
        managed_disk_type = "Standard_LRS"
        disk_size_gb = 64
    }

    os_profile {
        computer_name = "tf-demo-vm-ci"
        admin_username = "rajanaka"
        admin_password = "Ramaz@770866"
    }

    os_profile_linux_config {
        disable_password_authentication = false
    }
}
