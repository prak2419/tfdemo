locals { 
nsgrules = {
   
 sql = {
      name                       = "sql"
      priority                   = 101
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "1433"
      source_address_prefix      = "SqlManagement"
      destination_address_prefix = "*"
    }
 
    http = {
      name                       = "http-s"
      priority                   = 201
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "80-443"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  }
 
}