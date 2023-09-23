# VPC
resource "aws_vpc" "roboshop" {
  cidr_block = var.cidr_block
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support = var.enable_dns_support
  
  tags = merge( 
    var.common_tags,
    {
        Name = var.project_name
    },
    var.vpc_tags
  )
}

# Internet gateway

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.roboshop.id

  tags = merge(
    var.common_tags,
    {
        Name = var.project_name
    },
    var.igw_tags
  )
}

# Public subnets in us-east-1a and us-east-1b

resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidr)
  map_public_ip_on_launch = true
  vpc_id     = aws_vpc.roboshop.id
  cidr_block = var.public_subnet_cidr[count.index]
  availability_zone = local.azs[count.index]

  tags = merge(
    var.common_tags,
    {
        Name = "${var.project_name}-public-${local.azs[count.index]}"
    }
  )
}

# Private subnets in us-east-1a and us-east-1b

resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidr)
  vpc_id     = aws_vpc.roboshop.id
  cidr_block = var.private_subnet_cidr[count.index]
  availability_zone = local.azs[count.index]

  tags = merge(
    var.common_tags,
    {
        Name = "${var.project_name}-private-${local.azs[count.index]}"
    }
  )
}

# Database subnets in us-east-1a and us-east-1b

resource "aws_subnet" "database" {
  count = length(var.database_subnet_cidr)
  vpc_id     = aws_vpc.roboshop.id
  cidr_block = var.database_subnet_cidr[count.index]
  availability_zone = local.azs[count.index]

  tags = merge(
    var.common_tags,
    {
        Name = "${var.project_name}-database-${local.azs[count.index]}"
    }
  )
}

# Public route table and adding route for internet gateway

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.roboshop.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(
    var.common_tags,
    {
        Name = "${var.project_name}-public"
    },
    var.public_route_table_tags
  )
}

# Elastci ip creation for private and public route tables

resource "aws_eip" "elastic" {
    domain = "vpc"
}

# NAT Gateway to provide outgoing internet connection for private and database subnets

resource "aws_nat_gateway" "natgw" {
  allocation_id = aws_eip.elastic.id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(
    var.common_tags,
    {
        Name = var.project_name
    },
    var.nat_gateway_tags
  )
  
  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.main]
}

# Private route table and adding route for nat gateway

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.roboshop.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.natgw.id
  }

  tags = merge(
    var.common_tags,
    {
        Name = "${var.project_name}-private"
    },
    var.private_route_table_tags
  )
}

# Database route table and adding route for nat gateway

resource "aws_route_table" "database" {
  vpc_id = aws_vpc.roboshop.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.natgw.id
  }

  tags = merge(
    var.common_tags,
    {
        Name = "${var.project_name}-database"
    },
    var.database_route_table_tags
  )
}

# Public route table association with public subnets

// Public route table --> roboshop-public-1a
// Public route table --> roboshop-public-1b

resource "aws_route_table_association" "public_association" {
  count = length(var.public_subnet_cidr)
  subnet_id = element(aws_subnet.public[*].id,count.index)
  route_table_id = aws_route_table.public.id
}

# Private route table association with private subnets

// Private route table --> roboshop-private-1a
// Private route table --> roboshop-private-1b

resource "aws_route_table_association" "private_association" {
  count = length(var.private_subnet_cidr)
  subnet_id = element(aws_subnet.private[*].id,count.index)
  route_table_id = aws_route_table.private.id
}

# Database route table association with database subnets

// Database route table --> roboshop-database-1a
// Database route table --> roboshop-database-1b

resource "aws_route_table_association" "database_association" {
  count = length(var.database_subnet_cidr)
  subnet_id = element(aws_subnet.database[*].id,count.index)
  route_table_id = aws_route_table.database.id
}

# Database subnets grouping

resource "aws_db_subnet_group" "group" {
  name  = var.project_name
  subnet_ids = aws_subnet.database[*].id
  tags = merge(
    var.common_tags,
    {
    Name = "${var.project_name}-database-subnet-group"
    },
    var.database_subnet_group_tags
  )
}




