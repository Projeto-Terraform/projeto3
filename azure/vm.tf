resource "azurerm_resource_group" "resource_group_vm" {
  name     = "vm"
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_public_ip" "public_ip" {
  name                = "public-ip-terraform"
  resource_group_name = azurerm_resource_group.resource_group_vm.name
  location            = var.location
  allocation_method   = "Dynamic"

  tags = local.common_tags
}

resource "azurerm_network_interface" "network_interface" {
  name                = "network-interface-terraform"
  location            = var.location
  resource_group_name = azurerm_resource_group.resource_group_vm.name

  ip_configuration {
    name                          = "public-ip-terraform"
    subnet_id                     = data.terraform_remote_state.vnet.outputs.subnet_id_azure
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }

  tags = local.common_tags
}

resource "azurerm_network_interface_security_group_association" "nisga" {
  network_interface_id      = azurerm_network_interface.network_interface.id
  network_security_group_id = data.terraform_remote_state.vnet.outputs.security_group_id_azure
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                  = "vm-terraform"
  resource_group_name   = azurerm_resource_group.resource_group_vm.name
  location              = var.location
  size                  = "Standard_B1s"
  admin_username        = "terraform"
  network_interface_ids = [azurerm_network_interface.network_interface.id]

  # colocar o comando abaixo no terminal para gerar as chaves localmente:
  # ssh-keygen -f key-vm
  admin_ssh_key {
    username   = "terraform"
    public_key = file("./key-vm.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

  provisioner "local-exec" {
        command = "echo ${self.public_ip} >> public-ip.txt"
    }

    provisioner "file" {
        source = "./teste.txt"
        destination = "/tmp/finalcursoterraform.txt"
    }

    provisioner "file" {
        content = "public_ip: ${self.public_ip}"
        destination = "/tmp/public-ip.txt"
    }

    connection {
        type = "ssh"
        user = "ubuntu"
        private_key = file("./aws-key")
        host = self.public_ip
    }

    provisioner "remote-exec" {
        inline = [
            "echo ami: ${self.ami} >> /tmp/ami.txt",
            "echo private_ip: ${self.private_ip} >> /tmp/private_ip.txt",
        ]
    }

  tags = local.common_tags
}

# Para acessar a vm pelo terminal: ssh -i nomeDoArquivoChavePrivada nomeUsuarioQueCriamos@IP-VM
