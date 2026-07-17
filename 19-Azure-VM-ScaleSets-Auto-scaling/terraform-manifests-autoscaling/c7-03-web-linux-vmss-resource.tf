# Locals Block for custom data
locals {
  webvm_custom_data = <<-CUSTOM_DATA
#!/bin/bash

# Install Apache
dnf install -y httpd

# Enable and start Apache
systemctl enable --now httpd

# Configure firewalld
systemctl enable --now firewalld
firewall-cmd --permanent --add-service=http
firewall-cmd --reload

# Create application directory
mkdir -p /var/www/html/app1

# Home page
echo "Welcome to StackSimplify - WebVM App1 - VM Hostname: $(hostname)" > /var/www/html/index.html

# Application pages
echo "Welcome to StackSimplify - WebVM App1 - VM Hostname: $(hostname)" > /var/www/html/app1/hostname.html
echo "Welcome to StackSimplify - WebVM App1 - App Status Page" > /var/www/html/app1/status.html

cat > /var/www/html/app1/index.html <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>StackSimplify</title>
</head>
<body style="background-color:rgb(250,210,210);">
    <h1>Welcome to Stack Simplify - WebVM APP-1</h1>
    <p>Terraform Demo</p>
    <p>Application Version: V1</p>
</body>
</html>
EOF

# Azure Instance Metadata
curl -H "Metadata:true" \
     --noproxy "*" \
     "http://169.254.169.254/metadata/instance?api-version=2020-09-01" \
     -o /var/www/html/app1/metadata.html

CUSTOM_DATA
}


# Resource: Azure Linux Virtual Machine Scale Set - App1
resource "azurerm_linux_virtual_machine_scale_set" "web_vmss" {
  name                = "${local.resource_name_prefix}-web-vmss"
  #computer_name_prefix = "vmss-app1" # if name argument is not valid one for VMs, we can use this for VM Names
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard_DS1_v2"
  instances           = 2
  admin_username      = "azureuser"

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("${path.module}/ssh-keys/terraform-azure.pub")
  }

  source_image_reference {
    publisher = "RedHat"
    offer = "RHEL"
    sku = "9-lvm-gen2"
    version = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  upgrade_mode = "Automatic"
  
  network_interface {
    name    = "web-vmss-nic"
    primary = true
    network_security_group_id = azurerm_network_security_group.web_vmss_nsg.id
    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = azurerm_subnet.websubnet.id  
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.web_lb_backend_address_pool.id]
    }
  }
  #custom_data = filebase64("${path.module}/app-scripts/redhat-app1-script.sh")      
  custom_data = base64encode(local.webvm_custom_data)  
}
  

