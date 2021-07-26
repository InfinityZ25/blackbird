terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "2.10.1"
    }
  }
}
# Access token for DigitalOcean, stored in ENV variable DO_TOKEN
# Use export command with TF_VAR_variableName and value on setup
variable "do_token" {}
variable "pvt_key" {}

# Configure the DigitalOcean Provider
provider "digitalocean" {
  token = var.do_token
}
# Get ssh key
data "digitalocean_ssh_key" "terraform" {
  name = "jcedeno"
}

# Create a resource
resource "digitalocean_droplet" "mc2" {
  image  = "88607383"
  name   = "mc2"
  region = "nyc3"
  size   = "s-4vcpu-8gb-amd"
  ssh_keys = [
    data.digitalocean_ssh_key.terraform.id
  ]
  monitoring = true
  # Setup Connection Data
  connection {
    host        = self.ipv4_address
    user        = "root"
    type        = "ssh"
    private_key = file(var.pvt_key)
    timeout     = "2m"
  }
  # Here goes the actual script that will run in the droplet
  provisioner "remote-exec" {
    inline = [
      "export PATH=$PATH:/usr/bin",
      # Create directory for minecraft server
      "sudo mkdir /home/minecraft",
      "cd /home/minecraft",
      # Download Minecraft Server 1.16.5
      "wget https://api.pl3x.net/v2/purpur/1.16.5/latest/download -O server.jar",
      # Write script
      "cat >> start.sh <<EOL",
      "#!/bin/bash",
      "screen -dmS server java -Xmx$((${self.memory}-512))M -Xms1024m -jar server.jar",
      "echo Created a server with screen name \"server\" on ip ${self.ipv4_address} ",
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
      "sudo ./start.sh",
    ]
  }
}
