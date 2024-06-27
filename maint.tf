
provider "aws" {
  region = "eu-west-1" 
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

module "vpc" {
  source = "./vpc"
}

module "igw_nat" {
  source = "./igw_nat"
}

module "route_tables" {
  source = "./route_tables"
}

module "security_groups" {
  source = "./security_groups"
}

module "ec2_instances" {
  source = "./ec2_instances"
}

module "load_balancers" {
  source = "./load_balancers"
}

module "rds" {
  source = "./rds"
}

module "route53" {
  source = "./route53"
}

module "waf" {
  source = "./waf"
}

module "backup" {
  source = "./backup"
}

module "iam" {
  source = "./iam"
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "alb_dns_name" {
  value = module.load_balancers.alb_dns_name
}

output "db_instance_endpoint" {
  value = module.rds.db_instance_endpoint
}
