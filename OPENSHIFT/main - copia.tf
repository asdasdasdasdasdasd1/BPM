provider "azurerm" {
    version = "2.0.0"
    subscription_id = "ec82af24-731a-4277-a043-b225234d5dbf" 
    tenant_id       = "cb73b7e8-bc59-4114-ac71-9ac0b5314866"
    client_id       = "47f4e21c-2267-4d17-a54c-687a6b3a3d3d"
    client_secret   = "x-2_CfY8-t~srw5U64N83DgFCjXRdaC_MG"
    features {}
}

resource "azurerm_resource_group" "RG-SUPPORT" {
  name     = "rg-support"
  location = "East US"
}
 
resource "azurerm_virtual_network" "VN-SUPPORT" {
  name                = "vnet-support"
  resource_group_name = azurerm_resource_group.RG-SUPPORT.name
  location            = azurerm_resource_group.RG-SUPPORT.location
  address_space       = ["172.250.0.0/16"]
}

resource "azurerm_subnet" "SUPPORT-SUBNET" {
  name                 = "subnet-support"
  resource_group_name  = azurerm_resource_group.RG-SUPPORT.name
  virtual_network_name = azurerm_virtual_network.VN-SUPPORT.name
  address_prefix       = "172.250.50.0/24"
}

resource "azurerm_network_security_group" "SUPPORT-NSG" {
  name                = "nsg-support"
  location            = azurerm_resource_group.RG-SUPPORT.location
  resource_group_name = azurerm_resource_group.RG-SUPPORT.name

  security_rule {
    name                       = "allow-ssh"
    description                = "allow-ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "allow-http"
    description                = "allow-http"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "allow-https"
    description                = "allow-https"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "SUPPORT-NSG-TO-SUBNET" {
  subnet_id                 = azurerm_subnet.SUPPORT-SUBNET.id
  network_security_group_id = azurerm_network_security_group.SUPPORT-NSG.id
}



###############################################################################
# VM FOR BASTION
###############################################################################

resource "azurerm_public_ip" "BASTION-PUBLIC-IP" {
  name                = "ip-public-bastion"
  location            = azurerm_resource_group.RG-SUPPORT.location
  resource_group_name = azurerm_resource_group.RG-SUPPORT.name
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "BASTION-INTERFACES" {
  name                = "interface-bastion"
  location            = azurerm_resource_group.RG-SUPPORT.location
  resource_group_name = azurerm_resource_group.RG-SUPPORT.name
  
  ip_configuration {
    name                          = "configurationbastion"
    subnet_id                     = azurerm_subnet.SUPPORT-SUBNET.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "172.250.50.200"
    public_ip_address_id          = azurerm_public_ip.BASTION-PUBLIC-IP.id
  }
}

resource "azurerm_linux_virtual_machine" "BASTION-VM" {
  name                  = "vm-bastion"
  resource_group_name = azurerm_resource_group.RG-SUPPORT.name
  location            = azurerm_resource_group.RG-SUPPORT.location
  network_interface_ids = [azurerm_network_interface.BASTION-INTERFACES.id]
  size                = "Standard_D1_v2"
  admin_username      = "user01"
  admin_password      = "p12345678."
  disable_password_authentication = false

  admin_ssh_key {
    username   = "user01"
    public_key = file("id_rsa.pub")
  }

  source_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "7.5"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  tags = {
    environment = "Produccion"
  }
}


###############################################################################
# VM NODE  ( 1 .. 3)
###############################################################################

resource "azurerm_network_interface" "NODE1-INTERFACES" {
  name                = "interface-node1"
  location            = azurerm_resource_group.RG-SUPPORT.location
  resource_group_name = azurerm_resource_group.RG-SUPPORT.name
  
  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.SUPPORT-SUBNET.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "172.250.50.17"
  }
}

resource "azurerm_linux_virtual_machine" "NODE1-VM" {
  name                  = "vm-node1"
  resource_group_name = azurerm_resource_group.RG-SUPPORT.name
  location            = azurerm_resource_group.RG-SUPPORT.location
  network_interface_ids = [azurerm_network_interface.NODE1-INTERFACES.id]
  size                = "Standard_D1_v2"
  admin_username      = "user01"
  admin_password      = "p12345678."
  disable_password_authentication = false

  admin_ssh_key {
    username   = "user01"
    public_key = file("id_rsa.pub")
  }

  source_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "7.5"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

}

resource "azurerm_managed_disk" "NODE1-DISK" {
  name                 = "managed-disk-node1"
  location             = azurerm_resource_group.RG-SUPPORT.location
  resource_group_name  = azurerm_resource_group.RG-SUPPORT.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 20
}

resource "azurerm_virtual_machine_data_disk_attachment" "NODE1-DISK-ATTACH" {
  managed_disk_id    = azurerm_managed_disk.NODE1-DISK.id
  virtual_machine_id = azurerm_linux_virtual_machine.NODE1-VM.id
  lun                = "3"
  caching            = "ReadWrite"
}

###############################################################################
# VM NODE  ( 1 .. 3) 2
###############################################################################

resource "azurerm_network_interface" "NODE2-INTERFACES" {
  name                = "interface-node2"
  location            = azurerm_resource_group.RG-SUPPORT.location
  resource_group_name = azurerm_resource_group.RG-SUPPORT.name
  
  ip_configuration {
    name                          = "testconfiguration2"
    subnet_id                     = azurerm_subnet.SUPPORT-SUBNET.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "172.250.50.18"
  }
}

resource "azurerm_linux_virtual_machine" "NODE2-VM" {
  name                  = "vm-node2"
  resource_group_name = azurerm_resource_group.RG-SUPPORT.name
  location            = azurerm_resource_group.RG-SUPPORT.location
  network_interface_ids = [azurerm_network_interface.NODE2-INTERFACES.id]
  size                = "Standard_D1_v2"
  admin_username      = "user01"
  admin_password      = "p12345678."
  disable_password_authentication = false

  admin_ssh_key {
    username   = "user01"
    public_key = file("id_rsa.pub")
  }

  source_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "7.5"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

}

resource "azurerm_managed_disk" "NODE2-DISK" {
  name                 = "managed-disk-node2"
  location             = azurerm_resource_group.RG-SUPPORT.location
  resource_group_name  = azurerm_resource_group.RG-SUPPORT.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 20
}

resource "azurerm_virtual_machine_data_disk_attachment" "NODE2-DISK-ATTACH" {
  managed_disk_id    = azurerm_managed_disk.NODE2-DISK.id
  virtual_machine_id = azurerm_linux_virtual_machine.NODE2-VM.id
  lun                = "3"
  caching            = "ReadWrite"
}




#############################################################################################################
# DNS private
#############################################################################################################

resource "azurerm_private_dns_zone" "DNS-PRIVATE" {
  name                = "mariadb.pichincha.cloud"
  resource_group_name = azurerm_resource_group.RG-SUPPORT.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "DNS-VIRTUAL-NETWORK" {
  name                  = "dns-virtual-network"
  resource_group_name   = azurerm_resource_group.RG-SUPPORT.name
  private_dns_zone_name = azurerm_private_dns_zone.DNS-PRIVATE.name
  virtual_network_id    = azurerm_virtual_network.VN-SUPPORT.id
  registration_enabled  = true
}


###############################################################
# OUTPUT 
###############################################################

output "IP-PUBLIC-BASTION" {
  value = azurerm_public_ip.BASTION-PUBLIC-IP.ip_address
}