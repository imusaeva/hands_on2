# create vpc:
module "vpc" {
  source = "./vpc_module"
}

# lookup available azs in my region:
data "aws_availability_zones" "azs" {
  state = "available"
}

# create public 1a subnet:
module "public-1a-subnet" {
  source                  = "./subnet_module"
  vpc_id                  = module.vpc.id
  subnet_cidr_block       = "10.0.0.0/26"
  availability_zone       = data.aws_availability_zones.azs.names[0]
  map_public_ip_on_launch = true
  subnet_tag              = "public-1a"
}

# create public 1b subnet:
module "public-1b-subnet" {
  source                  = "./subnet_module"
  vpc_id                  = module.vpc.id
  subnet_cidr_block       = "10.0.0.64/26"
  availability_zone       = data.aws_availability_zones.azs.names[1]
  map_public_ip_on_launch = true
  subnet_tag              = "public-1b"
}

# create private 1a subnet:
module "private-1a-subnet" {
  source                  = "./subnet_module"
  vpc_id                  = module.vpc.id
  subnet_cidr_block       = "10.0.0.128/26"
  availability_zone       = data.aws_availability_zones.azs.names[0]
  map_public_ip_on_launch = false
  subnet_tag              = "private-1a"
}

# create private 1b subnet:
module "private-1b-subnet" {
  source                  = "./subnet_module"
  vpc_id                  = module.vpc.id
  subnet_cidr_block       = "10.0.0.192/26"
  availability_zone       = data.aws_availability_zones.azs.names[1]
  map_public_ip_on_launch = false
  subnet_tag              = "private-1b"
}

module "igw" {
  source  = "./igw_module"
  vpc_id  = module.vpc.id
  igw_tag = "igw"
}

module "natgw" {
  source          = "./natgw_module"
  natgw_eip_tag   = "nat_eip"
  natgw_subnet_id = module.public-1b-subnet.subnet_id
  natgw_tag       = "natgw"
}

module "public-rtb" {
  source         = "./rtb_module"
  vpc_id         = module.vpc.id
  gateway_id     = module.igw.id # igw-00394c6fba96d9470
  nat_gateway_id = null
  subnet_ids     = [module.public-1a-subnet.subnet_id, module.public-1b-subnet.subnet_id]
}

module "private-rtb" {
  source         = "./rtb_module"
  vpc_id         = module.vpc.id
  gateway_id     = null
  nat_gateway_id = module.natgw.id # nat-09778c7c16755ec38
  subnet_ids     = [module.private-1a-subnet.subnet_id, module.private-1b-subnet.subnet_id]
}

module "ec2-sg" {
  source  = "./sg_module"
  sg_name = "public-ec2-sg"
  vpc_id  = module.vpc.id
  rules = {
    0 = ["ingress", "0.0.0.0/0", 22, 22, "TCP", "allow ssh from www"]
    1 = ["egress", "0.0.0.0/0", 0, 65535, "-1", "allow outbound traffic to www"]
    2 = ["ingress", "0.0.0.0/0", 80, 80, "TCP", "allow http from www"]
  }
}

# lookup my ssh key:
data "aws_key_pair" "my_key" {
  key_name = "tentek"
}

# lookup latest amazon-linux-2 AMIs:
data "aws_ami" "amazon-linux-2_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

# create public 1a ec2:
module "public-1a-ec2" {
  source                 = "./ec2_module"
  ami                    = data.aws_ami.amazon-linux-2_ami.id
  instance_type          = "t2.micro"
  subnet_id              = module.public-1a-subnet.subnet_id
  key_name               = data.aws_key_pair.my_key.key_name
  vpc_security_group_ids = [module.ec2-sg.id]
  ec2_tag = "public-1a-ec2"
  user_data              = <<EOT
  #!/bin/bash
  yum update -y
  yum install httpd -y
  echo "<h1>this is public 1a ec2</h1>" > /var/www/html/index.html 
  systemctl start httpd
  systemctl enable httpd
  EOT
}

# create public 1b ec2:
module "public-1b-ec2" {
  source                 = "./ec2_module"
  ami                    = data.aws_ami.amazon-linux-2_ami.id
  instance_type          = "t2.micro"
  subnet_id              = module.public-1b-subnet.subnet_id
  key_name               = data.aws_key_pair.my_key.key_name
  vpc_security_group_ids = [module.ec2-sg.id]
  ec2_tag = "public-1b-ec2"
  user_data              = <<EOT
  #!/bin/bash
  yum update -y
  yum install httpd -y
  echo "<h1>*****this is public 1b ec2******</h1>" > /var/www/html/index.html 
  systemctl start httpd
  systemctl enable httpd
  EOT
}