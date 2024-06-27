variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "admin_subnet_cidrs" {
  default = ["10.0.7.0/24", "10.0.8.0/24"]
}

variable "private_subnet_cidrs" {
  default = ["10.0.3.0/24", "10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}

variable "availability_zones" {
  default = ["eu-west-1a", "eu-west-1b"] # Change to your desired AZs
}

variable "domain_name" {
  description = "The domain name for the application"
  default     = "example.com" # Change to your desired domain name
}

variable "hosted_zone_id" {
  description = "The Route 53 Hosted Zone ID for the domain"
  default     = "Z1234567890ABCDEFG" # Change to your hosted zone ID
}
