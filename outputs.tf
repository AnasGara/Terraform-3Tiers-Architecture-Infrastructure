output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "admin_subnet_ids" {
  value = aws_subnet.admin[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "alb_dns_name" {
  value = aws_lb.alb.dns_name
}

output "db_instance_endpoint" {
  value = aws_db_instance.main.endpoint
}
