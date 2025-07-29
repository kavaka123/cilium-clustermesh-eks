# VPC Peering Module

locals {
  tags = merge(
    var.common_tags,
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terragrunt"
    }
  )
}

# VPC Peering Connection (initiated from requester)
resource "aws_vpc_peering_connection" "main" {
  region      = var.requester_region
  vpc_id      = var.requester_vpc_id
  peer_vpc_id = var.accepter_vpc_id
  peer_region = var.accepter_region
  auto_accept = false

  tags = merge(
    local.tags,
    {
      Name = "${var.project_name}-${var.environment}-vpc-peering"
      Side = "Requester"
    }
  )
}

# Accept VPC Peering Connection (from accepter)
resource "aws_vpc_peering_connection_accepter" "accepter" {
  region                    = var.accepter_region
  vpc_peering_connection_id = aws_vpc_peering_connection.main.id
  auto_accept               = true

  tags = merge(
    local.tags,
    {
      Name = "${var.project_name}-${var.environment}-vpc-peering"
      Side = "Accepter"
    }
  )
}

# Routes from requester to accepter
resource "aws_route" "requester_to_accepter" {
  count = length(var.requester_route_table_ids)

  route_table_id            = var.requester_route_table_ids[count.index]
  destination_cidr_block    = var.accepter_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.main.id

  depends_on = [aws_vpc_peering_connection_accepter.accepter]

  timeouts {
    create = "2m"
  }
}

# Routes from accepter to requester
resource "aws_route" "accepter_to_requester" {
  count = length(var.accepter_route_table_ids)

  region                    = var.accepter_region
  route_table_id            = var.accepter_route_table_ids[count.index]
  destination_cidr_block    = var.requester_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.main.id

  depends_on = [aws_vpc_peering_connection_accepter.accepter]

  timeouts {
    create = "2m"
  }
}

# Security group rule for cross-cluster communication (requester)
resource "aws_security_group_rule" "requester_cross_cluster_ingress" {

  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = [var.accepter_vpc_cidr]
  security_group_id = var.requester_security_group_id
  description       = "Allow all traffic from accepter VPC"

  depends_on = [aws_vpc_peering_connection_accepter.accepter]
}

# Security group rule for cross-cluster communication (accepter)
resource "aws_security_group_rule" "accepter_cross_cluster_ingress" {
  region = var.accepter_region

  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = [var.requester_vpc_cidr]
  security_group_id = var.accepter_security_group_id
  description       = "Allow all traffic from requester VPC"

  depends_on = [aws_vpc_peering_connection_accepter.accepter]
}
