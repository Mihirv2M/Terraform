//----VPC Created
resource "aws_vpc" "My_VPC" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "My-VPC"
  }
}


//----Public Subnet Created
resource "aws_subnet" "public_subnets" {
  count = length(var.public_subnet_cidrs)
  vpc_id = aws_vpc.My_VPC.id
  cidr_block = element(var.public_subnet_cidrs, count.index)
  availability_zone = element(var.azs, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "Public Subnet ${count.index + 1}"
  }
}

//----Private Subnet Created
resource "aws_subnet" "private_subnets" {
  count = length(var.private_subnet_cidrs)
  vpc_id = aws_vpc.My_VPC.id
  cidr_block = element(var.private_subnet_cidrs, count.index)
  availability_zone = element(var.azs, count.index)

  tags = {
    Name = "Private Subnet ${count.index + 1}"
  }
}

//----Internet Gateway Attached
resource "aws_internet_gateway" "mig" {
  vpc_id = aws_vpc.My_VPC.id

  tags = {
    Name = "My VPC IG"
  }
}

//----Create Route Table for Public Subnets
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.My_VPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mig.id
  }

  tags = {
    Name = "Public Route Table"
  }
}

//----Associate Public Route Table with Public Subnets
resource "aws_route_table_association" "public_subnet_asso" {
  count = length(aws_subnet.public_subnets)
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}

//----Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  vpc = true

  tags = {
    Name = "Elastic IP"
  }
}

//----Create NAT Gateway
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_subnets[0].id  # Adjust as needed

  tags = {  
    Name = "NAT-Gateway"
  }
}

//----Private Route Table Created
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.My_VPC.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "Private Route Table"
  }
}

//----Private Subnet Route Table Association
resource "aws_route_table_association" "private_subnet_asso" {
  count = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private_route_table.id
}

//----Public Security Group
resource "aws_security_group" "public_sg" {
  vpc_id = aws_vpc.My_VPC.id

  tags = {
    Name = "Public SG"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  } 

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

//----Private Security Group
resource "aws_security_group" "private_sg" {
  vpc_id = aws_vpc.My_VPC.id

  tags = {
    Name = "Private SG"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

//----TLS Key for EC2 Instance
resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "TF_key" {
  key_name   = "TF_key"
  public_key = tls_private_key.rsa.public_key_openssh
}

resource "local_file" "TF_key" {
  content  = tls_private_key.rsa.private_key_pem
  filename = "TF_key"
}

//----EC2 Instance Created
resource "aws_instance" "my_instance" {
  ami           = var.image_id
  instance_type = var.instance_type
  key_name      = aws_key_pair.TF_key.key_name
  subnet_id     = aws_subnet.public_subnets[0].id  # Referencing the first public subnet
  vpc_security_group_ids = [aws_security_group.public_sg.id]
  associate_public_ip_address = true    

  user_data = var.user_data_demo


  tags = {
    Name = "Terraform"
  }
}

#resource "aws_instance" "second_instance" {
# ami                            = var.image_id
#  instance_type                  = var.instance_type
#  key_name                       = aws_key_pair.TF_key.key_name
#  subnet_id                      = aws_subnet.public_subnets[1].id  # Referencing the second
#  vpc_security_group_ids         = [aws_security_group.public_sg.id]
#   associate_public_ip_address    = true
#  depends_on                     = [aws_instance.my_instance]
#  user_data                      = var.user_data_demo

#  tags = {
#    Name = "Terraform2"
#  }
#}

resource "aws_lb" "application_lb" {
  name = var.alb_name
  internal = false
  ip_address_type = "ipv4"
  load_balancer_type = var.alb_type
  security_groups = [aws_security_group.public_sg.id]
  subnets            = aws_subnet.public_subnets[*].id

  tags = {
    Name="Test-alb"
  }
}

resource "aws_lb_target_group" "target-group" {
 
  name = var.alb_tg_name
  port = 80
  protocol = var.alb_protocol
  target_type = "instance"
  vpc_id = aws_vpc.My_VPC.id

    health_check {
      interval = 10
      path = "/"
      protocol = var.alb_protocol
      timeout = 5
      healthy_threshold = 5
      unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.application_lb.arn
  port = 80
  protocol = var.alb_protocol
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.target-group.arn
  }
}
resource "aws_lb_target_group_attachment" "instance_attachment" {
  target_group_arn = aws_lb_target_group.target-group.arn
  target_id = aws_instance.my_instance.id
  port = 80
}

resource "aws_volume_attachment" "ebs" {
  device_name = "/dev/sdf"
  volume_id = aws_ebs_volume.volume.id
  instance_id = aws_instance.my_instance.id
}

resource "aws_ebs_volume" "volume" {
  availability_zone = "us-east-1a"
  size = 1
}

resource "aws_ebs_snapshot" "backup" {
  volume_id = aws_ebs_volume.volume.id
  tags = {
    Name = "my-snapshot"
  }
}
