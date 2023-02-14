provider "aws" {
  region = var.region
}


module "myvpc" {

  // Get the reference to the variable.
  source = "github.com/apulijala/tf_vpc_basic.git?ref=v0.0.3"
  dns_host_names = var.dns_host_names
  map_public_ip_on_launch = var.map_public_ip_on_launch
  dns_support = var.dns_support
  name = var.vpc_name
  vpc_cidr = "10.0.0.0/16"
  subnet_cidr = "10.0.0.0/24"

}

// Security Group of Web Host
resource "aws_security_group" "web_host" {

  name        = "allow_web_and_tls"
  description = "Allow  Web and TLS inbound traffic"
  vpc_id      = module.myvpc.vpc_id

  // Opening port number to vpc CIDR ranges.
  ingress {

    description = "Http From within VPC."
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [module.myvpc.vpc_cidr]

  }

  // Operning ssh ports to outside workd. unsafe.
  ingress {

    description = "TLS from all computers"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }


  // Open outbound traffic to all ports.
  egress {

    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }

  tags = {
    Name = "web_host"
  }
}
// Security Group of Web Load Balancer.

resource "aws_security_group" "web_lb" {

  name        = "allow_web_host"
  description = "Allow Traffic to Web Host"
  vpc_id      = module.myvpc.vpc_id

  // Ingress ports to port 80
  ingress {

    description = "Http From within VPC."
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  egress {

    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }
  tags = {
    Name = "web_alb"
  }
}

// Instances with Two IP addresses.

resource "aws_instance" "web_instance" {

  ami = var.ami[var.region]
  key_name = "terraform_key_pair"
  instance_type = var.instance_type
  subnet_id = module.myvpc.subnet_id
  private_ip = var.instance_ips[count.index]
  associate_public_ip_address = true
  vpc_security_group_ids = [ aws_security_group.web_host.id ]
  tags = {
    Name = "web-${format("%03d", count.index + 1 )}"
    Owner = element(var.owner_tag, count.index )
  }

  connection {
    // Find the first public ip and then if not found private_ip
    host        = coalesce(self.public_ip, self.private_ip)
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(var.key_path)
  }

  provisioner "file" {
    source      = "files/playbook.yaml"
    destination = "/tmp/playbook.yaml"
  }

  provisioner "file" {
    source      = "files/install_ansible.sh"
    destination = "/tmp/install_ansible.sh"
  }

  // Content Gernated by file provisioner can be source and
  // destination is  a file. Iterate over the index and then count.index.
  provisioner "file" {
    content = element(data.template_file.index[*].rendered, count.index )
    destination = "/tmp/index.html"
  }

  // Copy the inventory file to /tmp directory.
  provisioner "file" {

    source      = "files/inventory"
    destination = "/tmp/inventory"
  }

  //  Multiple commands can be entered here.

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install_ansible.sh",
      "bash /tmp/install_ansible.sh",
      "sudo cp  /tmp/index.html /usr/share/nginx/html/index.html"
    ]
  }

  // Two Counts of Instances.
  count = local.intance_ip_count
}

data "template_file" "index" {
  template =  file("files/index.html.tpl")
  vars = {
    // pass the host name to the tpl file.
    hostname = "web-${format("%03d", count.index + 1)}"
  }
  count = length(var.instance_ips)
}


// Load Balanncer
resource "aws_elb" "web_alb" {

  name    = "web-elb"
  subnets = [module.myvpc.subnet_id]
  security_groups = [aws_security_group.web_lb.id]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }
  instances  = aws_instance.web_instance[*].id

  tags = {
    Name = "web-elb"
  }
}

// # First need to install Ansible. Need to transfer file, inventory file and the playbook file.








