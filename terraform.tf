provider "aws" {
  region = "ap-south-1"
}

resource "aws_vpc" "ansible-vpc" {
  cidr_block = "10.0.0.0/24"
  tags = {
    Name = "ansible-vpc"
  }
}

resource "aws_subnet" "ansible-pub-sub" {
  vpc_id = aws_vpc.ansible-vpc.id
  availability_zone = "ap-south-1a"
  cidr_block = "10.0.0.0/25"
  tags = {
    Name = "ansible-pub-sub"
  }
}

resource "aws_subnet" "ansible-pri-sub" {
  vpc_id = aws_vpc.ansible-vpc.id
  availability_zone = "ap-south-1a"
  cidr_block = "10.0.0.128/25"
  tags = {
    Name = "ansible-pri-sub"
  }
}

resource "aws_default_security_group" "default" {
  vpc_id      = aws_vpc.ansible-vpc.id

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "6"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ansible-pub-sg"
  }
}

resource "aws_instance" "ansible-control-node" {
  ami = "ami-02a2af70a66af6dfb"
  instance_type = "t2.micro"
  key_name = "aws-private-key"
  subnet_id = aws_subnet.ansible-pub-sub.id
  associate_public_ip_address = true
  tags = {
    Name = "Control-Node-ansible"
  }
}

resource "aws_instance" "ansible-centos" {
  ami = "ami-02a2af70a66af6dfb"
  instance_type = "t2.micro"
  key_name = "aws-private-key"
  subnet_id = aws_subnet.ansible-pri-sub.id
  tags = {
    Name = "ansible-centos"
  }
}

resource "aws_instance" "ansible-ubuntu" {
  ami = "ami-0287a05f0ef0e9d9a"
  instance_type = "t2.micro"
  key_name = "aws-private-key"
  subnet_id = aws_subnet.ansible-pri-sub.id
  tags = {
    Name = "ansible-ubuntu"
  }
}

resource "aws_internet_gateway" "ansible-igw" {
  vpc_id = aws_vpc.ansible-vpc.id
  tags = {
    Name = "ansible-igw"
  }
}

resource "aws_route_table" "pub-ansible-rt" {
  vpc_id = aws_vpc.ansible-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ansible-igw.id
  }

  tags = {
    Name = "pub-ansible-rt"
  }
}

resource "aws_route_table_association" "ans-pub-rt-association" {
  subnet_id = aws_subnet.ansible-pub-sub.id
  route_table_id = aws_route_table.pub-ansible-rt.id
}

resource "aws_eip" "nat-ip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "ansible-nat" {
  allocation_id = aws_eip.nat-ip.id
  subnet_id     = aws_subnet.ansible-pub-sub.id

  tags = {
    Name = "ansible-nat"
  }
}

resource "aws_route_table" "nat-rt" {
  vpc_id = aws_vpc.ansible-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.ansible-nat.id
  }

  tags = {
    Name = "nat-rt"
  }
}

resource "aws_route_table_association" "nat-pri-association" {
  subnet_id = aws_subnet.ansible-pri-sub.id
  route_table_id = aws_route_table.nat-rt.id
}
