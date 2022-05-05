/* Assign a Cloud Provider*/

provider "aws" {}


/*List necessary variables*/

variable vpc_cidr_block {}
variable subnet_cidr_block {}
variable avail_zone {}
variable env_prefix {}
variable my_ip {}
variable instance_type {}
variable public_key_location {}

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


/* Set tag to show Server Name*/

    tags = {
      Name: "${var.env_prefix}-sg"
    }
}


/* To always get the latest Amazon AMI Image Owner and Virtualization_type as the filter attributes*/

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


/* Terraform Displays the AMI-ID as OUTPUT after applying the configs */

    output  "aws_ami_id" {
        value = data.aws_ami.latest-amazon-linux-image.id
}
    

/* Terraform Displays the PUBLIC-IP ADDRESS of the HOST after applying the configs */

    output "ec2_public_ip" {
        value = aws_instance.myapp-server.public_ip 
  
}


/* Using Terraform to generate the key pairs in other to ssh into the server */
/* First declear the a variable to refrence the key location. */
/* In this case, the variable is "var.public_key_location", */
/* The "${file()}"  is used to read the file location */ 

    resource "aws_key_pair" "ssh-key" {
    	key_name = "server-key"
    	public_key = "${file(var.public_key_location)}"

}


/* This section create the EC2-INSTANCE and also assigns the instance-type, subnet-id, SG and AZ */

    resource "aws_instance" "myapp-server" {
        ami = data.aws_ami.latest-amazon-linux-image.id
        instance_type = var.instance_type

        subnet_id = aws_subnet.myapp-subnet-1.id
        vpc_security_group_ids = [ aws_default_security_group.default-sg.id ]
        availability_zone = var.avail_zone

        associate_public_ip_address = true
        key_name = aws_key_pair.ssh-key.key_name


        user_data = file("entry-script.sh")
           

/* The tag is used to name the server */

        tags = {
            Name = "${var.env_prefix}-server"
    }
}

