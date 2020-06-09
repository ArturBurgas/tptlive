provider "azurerm" {
    # The "feature" block is required for AzureRM provider 2.x. 
    # If you're using version 1.x, the "features" block is not allowed.
    version = "~>2.0"
    features {}

 
    subscription_id = ""
	client_id 		= ""
	client_secret	= ""
    tenant_id       = ""
 
}

resource "azurerm_resource_group" "rg1"{
	name     = "rg1"
  # You should use variables to provide information, which could be flexible, hardcoding is bad idea
  # Also using variables, allows you to change some settings on a fligh, using command "terraform apply -var foo=bar"
  # Not everything should be configured as a variables, but such data as regions, names, ips, and sku's should be
	location = "${var.location}"
}

resource "azurerm_virtual_network" "vnet1" {
  name                = "example-network"
  address_space       = ["10.0.0.0/16"]
  # Best Practices to implement references using pattern -> "${}"
  # In most cases will work, but some specific functioning could be broken
  # Check in above how it is done using variables
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
}

resource "azurerm_subnet" "subnet1" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.rg1.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefix       = "10.0.2.0/24"
}

resource "azurerm_network_interface" "nic1" {
  name                = "example-nic"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
	public_ip_address_id          = azurerm_public_ip.pub_ip1.id
  }
}

resource "azurerm_linux_virtual_machine" "vm1" {
  name                = "vm1"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location
  
  size                = "Standard_F2s_v2"
  admin_username      = "admin"
  
  network_interface_ids = [
    azurerm_network_interface.nic1.id,
  ]

  admin_ssh_key {
    username   = "user"
    public_key = file("C:\\Users\\Artur\\Desktop\\terraform\\sshpublic.key")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}
resource "azurerm_storage_account" "stracca2" {
  name                     = "stracc2"
  resource_group_name      = azurerm_resource_group.rg1.name
  location                 = azurerm_resource_group.rg1.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  
}
resource "azurerm_public_ip" "pub_ip1" {
  name                = "pub_ip1"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  allocation_method   = "Static"

  
}

data "azurerm_public_ip" "pub_ip1" {
  name                = azurerm_public_ip.pub_ip1.name
  resource_group_name = azurerm_linux_virtual_machine.vm1.resource_group_name
}

output "public_ip_address" {
  value = data.azurerm_public_ip.pub_ip1.ip_address
}