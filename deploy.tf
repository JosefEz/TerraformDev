/* Assign a Cloud Provider*/

provider "aws" {}


/*List necessary variables*/

variable vpc_cidr_block {}
variable subnet_cidr_block {}
variable avail_zone {}
variable env_prefix {}
variable my_ip{}
variable instance_type {}

/* Create VPC Resource and Assign the VPC_CIDR_BLOCK Variable*/

resource "aws_vpc" "myapp-vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
      Name: "${var.env_prefix}-vpc"
  }
}

/* Create SUBNET Resource and Assign the SUBNET_CIDR_BLOCK Variable*/

resource "aws_subnet" "myapp-subnet-1" {
  vpc_id = aws_vpc.myapp-vpc.id
  cidr_block = var.subnet_cidr_block
  availability_zone = var.avail_zone
  tags = {
    Name: "${var.env_prefix}-subnet-1"
  }
}


/* Create Internet Gateway  Resource and Attach the VPC resource ID*/

resource "aws_internet_gateway" "myapp-igw" {
    vpc_id = aws_vpc.myapp-vpc.id
    tags = {
      Name = "${var.env_prefix}-igw"
    }

 }


/* Create Routing Table  Resource and Attach the Default VPC Routing Table*/
/* Also Attache the Internet Gateway Including the Allow all Route */

resource "aws_default_route_table" "main-rtb" {
    default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.myapp-igw.id
    }
  tags = {
    Name: "${var.env_prefix}-main-rtb"
  }
}

/* Use the Default Security Group Inside the VPC */

resource "aws_default_security_group" "default-sg" {
    vpc_id = aws_vpc.myapp-vpc.id

/* Create Ingress for SSH and NGINX Protocol and Assign the My_ip Variable*/

    ingress  {
      cidr_blocks = [ var.my_ip ]
      from_port = 22
      protocol = "tcp"
      to_port = 22
    }

    ingress   {
      cidr_blocks = [ "0.0.0.0/0" ]
      from_port = 8080
      protocol = "tcp"
      to_port = 8080
    }

/* Create Egress for Any Network and Any Protcol */
    egress {
       cidr_blocks = [ "0.0.0.0/0" ]
      from_port = 0
      protocol = "-1"
      to_port = 0
      prefix_list_ids = []
    }

    tags = {
      Name: "${var.env_prefix}-sg"
    }
}

    data "aws_ami" "latest-amazon-linux-image" {
        most_recent = true
        owners = ["amazon"]
        filter {
           name = "name"
           values = ["amzn2-ami-hvm-*-x86_64-gp2"]
 }

        filter {
           name = "virtualization-type"
           values = ["hvm"]
    }
}

    output "aws_ami_id" {
        value = data.aws_ami.latest-amazon-linux-image.id

}

    resource "aws_instance" "myapp-server" {
        ami = data.aws_ami.latest-amazon-linux-image.id
        instance_type = var.instance_type

        subnet_id = aws_subnet.myapp-subnet-1.id
        vpc_security_group_ids = [ aws_default_security_group.default-sg.id ]
        availability_zone = var.avail_zone

        associate_public_ip_address = true
        key_name = "docker_cent"

        tags = {
            Name: "${var.env_prefix}-server"
    }
}

