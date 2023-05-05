# Define provider
provider "aws" {
  region = "us-east-1"
}

# Retrieve information about the availability zones in the specified region
data "aws_availability_zones" "all" {}

# Create VPC
resource "aws_vpc" "example_vpc" {
  cidr_block = "10.0.0.0/16"
}

# Create public subnets in each availability zone for ELB
resource "aws_subnet" "example_public_subnet_elb_1" {
  count = length(data.aws_availability_zones.all.names)
  vpc_id = aws_vpc.example_vpc.id
  cidr_block = "10.0.${count.index}.0/24"
  availability_zone = data.aws_availability_zones.all.names[count.index]
}

# Create a private subnet in each availability zone for ASG
resource "aws_subnet" "example_private_subnet_asg_1" {
  count = length(data.aws_availability_zones.all.names)
  vpc_id = aws_vpc.example_vpc.id
  cidr_block = "10.0.${count.index + 10}.0/24"
  availability_zone = data.aws_availability_zones.all.names[count.index]
}

# Create an RDS subnet group with three subnets in different availability zones


# Create an internet gateway
resource "aws_internet_gateway" "example_igw" {
  vpc_id = aws_vpc.example_vpc.id
}

# Create a public route table for internet access
resource "aws_route_table" "example_public_route_table" {
  vpc_id = aws_vpc.example_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.example_igw.id
  }

  tags = {
    Name = "example-public-route-table"
  }
}

# Associate the public route table with the public subnets
resource "aws_route_table_association" "example_public_route_table_association" {
  count          = length(data.aws_availability_zones.all.names)
  subnet_id      = aws_subnet.example_public_subnet_elb_1.*.id[count.index]
  route_table_id = aws_route_table.example_public_route_table.id
}

# Create a private route table for ASG
resource "aws_route_table" "example_private_route_table" {
  vpc_id = aws_vpc.example_vpc.id

  tags = {
    Name = "example-private-route-table"
  }
}
