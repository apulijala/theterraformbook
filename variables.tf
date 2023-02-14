variable "region" {
  type = string
  description = "The AWS Region"
  default = "us-east-1"
}

variable "region_list" {
  type = list(string)
  default = ["us-eaat-1a", "us-east-1b"]
}

variable "ami" {

  type = map(string)
  default = {
    us-east-1 = "ami-0d729a60"
    us-west-1 = "ami-7c4b331c"
  }
  description = "The AMIs to Use"
}

variable "instance_type" {

  default = "t2.micro"
  description = "Instance Type"

}

variable "dns_host_names" {
  type = bool
}

variable "map_public_ip_on_launch" {
  type = bool
}

variable "dns_support" {
  type = bool
}

variable "web" {}

variable "vpc_name" {
  type = string
}

variable "instance_ips" {
  type = list(string)
  default = ["10.0.0.20", "10.0.0.21"]
}


variable "owner_tag" {

  type = list(string)
  default = ["team1", "team2"]

}

variable "environment" {
  type = string
  default = "development"
}

variable "key_path" {
  type = string
}


