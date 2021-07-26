# Use export command with TF_VAR_variableName and value on setup
variable "vultr_api_token" {}

provider "vultr" {
  # Configuration options
  api_key = var.vultr_api_token
}
data "vultr_ssh_key" "sshKey" {
  filter {
    name = "name"
    # Name of your ssh key in Vultr
    values = ["Juan Cedeno"]
  }
}

resource "vultr_instance" "sv" {
  plan   = "vhf-2c-4gb"
  region = "ewr"
  # Vultr OS ID for ubuntu 20.04
  os_id            = "387"
  label            = "terraform_deployment"
  hostname         = "blackbird"
  activation_email = false
  ssh_key_ids = [
    data.vultr_ssh_key.sshKey.id
  ]
  connection {
    host        = self.main_ip
    user        = "root"
    type        = "ssh"
    private_key = file(var.pvt_key)
    timeout     = "2m"
  }
  provisioner "remote-exec" {
    inline = [
      "export PATH=$PATH:/usr/bin",
      # Install java and screen
      "sudo apt update",
      "sudo apt install -y screen openjdk-16-jre-headless",
      # Create directory for minecraft server
      "sudo mkdir /home/minecraft",
      "cd /home/minecraft",
      # Download Minecraft Server 1.16.5
      "wget https://api.pl3x.net/v2/purpur/1.16.5/latest/download -O server.jar",
      # Write script
      "cat >> start.sh <<EOL",
      "#!/bin/bash",
      "sudo screen -dmS \"mcserver\" java -Xmx$((${self.ram}-1024))M -Xms1024m -jar server.jar",
      "echo Created a server with screen name \"server\" on ip ${self.main_ip} ",
      "EOL",
      # Accept the eula
      "echo \"eula=true\" >> eula.txt",
      # Disable nether on server.properties
      "echo allow-nether=false >> server.properties",
      # Disabled end on bukkit.yml start
      "cat >> bukkit.yml << EOL",
      "settings:",
      " allow-end: false",
      "EOL",
      # Disable end on bukkit.yml end
      # Run the start script
      "chmod +x start.sh",
      "sudo sh start.sh",
    ]
  }
}
