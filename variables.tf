variable "public_subnet_cidrs" {
  type = list(string)
  description = "Public Subnet CIDR Values"
  default = [ "10.0.1.0/24","10.0.2.0/24","10.0.3.0/24" ]
}

variable "private_subnet_cidrs" {
  type = list(string)
  description = "Private Subnet CIDR Values"
  default = [ "10.0.4.0/24","10.0.5.0/24","10.0.6.0/24" ]
}

variable "azs" {
  type = list(string)
  description = "Availability Zone" 
  default = [ "us-east-1a","us-east-1b","us-east-1c" ]
}

variable "image_id" {
    type = string
    description = "AMI ID"
    default = "ami-0182f373e66f89c85"
}
variable "instance_type" {
    type = string
    description = "INSTANCE TYPE"
    default = "t2.micro"
}

variable "user_data" {
  type = string
  default = "value"
}

variable "user_data_demo" {
  type = string
  default = <<-EOF
    #!/bin/bash
    sudo su
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "<h1>Hello World from ME To Terraform $(hostname -f)</h1>" > /var/www/html/index.html
    EOF
}

variable "alb_name" {
  type = string
  default = "my-alb"
}

variable "alb_type" {
  type = string
  default = "application"
}
variable "alb_protocol" {
  type = string
  default = "HTTP"
}
variable "alb_tg_name" {
  type = string
  default = "test-tg"
}
variable "bucket_name" {
  type = string
  default = "terraform-mihir-loacal-state"
}
variable "bucket_key" {
  type = string
  default = "terraform.tfstate"
}
variable "region" {
  type = string
  default = "us-east-1"
}
# variable "AWS_ACCESS_KEY_ID" {
#   type = string
#   default = "AKIA6GBMDF3TVJIWU5D6"
# }
# variable "AWS_SECRET_ACCESS_KEY" {
#   type = string
#   default = "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"
# }