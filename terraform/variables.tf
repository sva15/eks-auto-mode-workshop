variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-west-2"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "sandbox-vpc-eks-test"
}

variable "cluster_version" {
  description = "EKS cluster kubernetes version"
  type        = string
  default     = "1.32"
}

variable "eks_auto_node_pool" {
  description = "EKS Auto Mode Cluster Node Pool list"
  type        = list(string)
  default     = ["general-purpose", "system"]
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.20.0.0/19"
}

variable "azs" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b", "us-west-2c"]
}

variable "private_subnets" {
  description = "Private subnet CIDRs"
  type        = list(string)
  default     = ["10.20.0.0/21", "10.20.8.0/21", "10.20.16.0/21"]
}

variable "public_subnets" {
  description = "Public subnet CIDRs"
  type        = list(string)
  default     = ["10.20.24.0/23", "10.20.26.0/23", "10.20.28.0/23"]
}