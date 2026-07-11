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



# Resource: Azure Linux Virtual Machine
resource "azurerm_linux_virtual_machine" "web_linuxvm" {
  name = "${local.resource_name_prefix}-web-linuxvm"
  #computer_name = "web-linux-vm" # Hostname of the VM (Optional)
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location 
  size = "Standard_DS1_v2"
  admin_username = "azureuser"
  network_interface_ids = [ azurerm_network_interface.web_linuxvm_nic.id ]
  admin_ssh_key {
    username = "azureuser"
    public_key = file("${path.module}/ssh-keys/terraform-azure.pub")
  }
  os_disk {
    caching = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }  
  source_image_reference {
    publisher = "RedHat"
    offer = "RHEL"
    sku = "83-gen2"
    version = "latest"
  }  
  #custom_data = filebase64("${path.module}/app-scripts/redhat-webvm-script.sh")
  custom_data = base64encode(local.webvm_custom_data)
}
