# VPC Peering Module Variables

variable "project_name" {
  description = "Project name to be used as prefix for all resources"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

# Requester VPC Configuration
variable "requester_vpc_id" {
  description = "VPC ID of the requester"
  type        = string
}

variable "requester_region" {
  description = "AWS region of the requester VPC"
  type        = string
}

variable "requester_route_table_ids" {
  description = "Route table IDs in the requester VPC"
  type        = list(string)
}

variable "requester_security_group_id" {
  description = "Security group ID in the requester VPC"
  type        = string
}

variable "requester_vpc_cidr" {
  description = "CIDR block of the requester VPC"
  type        = string
}

# Accepter VPC Configuration
variable "accepter_vpc_id" {
  description = "VPC ID of the accepter"
  type        = string
}

variable "accepter_vpc_cidr" {
  description = "CIDR block of the accepter VPC"
  type        = string
}

variable "accepter_route_table_ids" {
  description = "Route table IDs in the accepter VPC"
  type        = list(string)
}

variable "accepter_security_group_id" {
  description = "Security group ID in the accepter VPC"
  type        = string
}

variable "accepter_region" {
  description = "AWS region of the accepter VPC"
  type        = string
}

variable "common_tags" {
  description = "Common tags to be applied to all resources"
  type        = map(string)
  default     = {}
}
