# VPC Peering Module Outputs

output "vpc_peering_connection_id" {
  description = "ID of the VPC peering connection"
  value       = aws_vpc_peering_connection.main.id
}

output "vpc_peering_connection_status" {
  description = "Status of the VPC peering connection"
  value       = aws_vpc_peering_connection_accepter.accepter.accept_status
}

output "requester_route_ids" {
  description = "IDs of the routes created in the requester VPC"
  value       = aws_route.requester_to_accepter[*].id
}

output "accepter_route_ids" {
  description = "IDs of the routes created in the accepter VPC"
  value       = aws_route.accepter_to_requester[*].id
}
