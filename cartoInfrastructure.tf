provider "aws" {
  region = "eu-west-1" 
}

# Variables
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

# VPC
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
}

# Subnets
resource "aws_subnet" "public" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = element(var.public_subnet_cidrs, count.index)
  availability_zone = element(var.availability_zones, count.index)
  map_public_ip_on_launch = true
}

resource "aws_subnet" "admin" {
  count             = length(var.admin_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = element(var.admin_subnet_cidrs, count.index)
  availability_zone = element(var.availability_zones, count.index)
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = element(var.private_subnet_cidrs, count.index)
  availability_zone = element(var.availability_zones, count.index % length(var.availability_zones))
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

# NAT Gateways
resource "aws_eip" "nat" {
  count = length(var.admin_subnet_cidrs)
  vpc   = true
}

resource "aws_nat_gateway" "main" {
  count         = length(var.admin_subnet_cidrs)
  allocation_id = element(aws_eip.nat.*.id, count.index)
  subnet_id     = element(aws_subnet.admin.*.id, count.index)
}

# Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

resource "aws_route_table_association" "public" {
  count      = length(aws_subnet.public.*.id)
  subnet_id  = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "admin" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.main.*.id, count.index)
  }
}

resource "aws_route_table_association" "admin" {
  count      = length(aws_subnet.admin.*.id)
  subnet_id  = element(aws_subnet.admin.*.id, count.index)
  route_table_id = aws_route_table.admin.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table_association" "private" {
  count      = length(aws_subnet.private.*.id)
  subnet_id  = element(aws_subnet.private.*.id, count.index)
  route_table_id = aws_route_table.private.id
}

# Security Groups
resource "aws_security_group" "frontend_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "backend_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    security_groups = [aws_security_group.frontend_sg.id, aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "rds_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    security_groups = [aws_security_group.backend_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "alb_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "admin_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Restrict this to your IP address for better security
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instances
resource "aws_instance" "frontend" {
  count = 2
  ami           = "ami-0c55b159cbfafe1f0" # Amazon Linux 2 AMI (replace with your desired AMI)
  instance_type = "t2.micro"
  subnet_id     = element(aws_subnet.private.*.id, count.index)
  security_groups = [aws_security_group.frontend_sg.name]

  tags = {
    Name = "Frontend Instance ${count.index + 1}"
  }
}

resource "aws_instance" "backend" {
  count = 2
  ami           = "ami-0c55b159cbfafe1f0" # Amazon Linux 2 AMI (replace with your desired AMI)
  instance_type = "t2.micro"
  subnet_id     = element(aws_subnet.private.*.id, count.index + 2) # Ensure backend instances are in different private subnets
  security_groups = [aws_security_group.backend_sg.name]

  tags = {
    Name = "Backend Instance ${count.index + 1}"
  }
}

resource "aws_instance" "admin" {
  count = 2
  ami           = "ami-0c55b159cbfafe1f0" # Amazon Linux 2 AMI (replace with your desired AMI)
  instance_type = "t2.micro"
  subnet_id     = element(aws_subnet.admin.*.id, count.index)
  security_groups = [aws_security_group.admin_sg.name]

  tags = {
    Name = "Admin Instance ${count.index + 1}"
  }
}

# Load Balancers
resource "aws_lb" "frontend" {
  name               = "frontend-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = aws_subnet.public.*.id
}

resource "aws_lb" "backend" {
  name               = "backend-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = aws_subnet.private.*.id
}

resource "aws_lb_target_group" "frontend" {
  name     = "frontend-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    interval            = 30
    path                = "/"
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group" "backend" {
  name     = "backend-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    interval            = 30
    path                = "/actuator/health" 
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "frontend" {
  load_balancer_arn = aws_lb.frontend.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

resource "aws_lb_listener" "backend" {
  load_balancer_arn = aws_lb.backend.arn
  port              = 8080
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }
}

resource "aws_lb_target_group_attachment" "frontend" {
  count            = 2
  target_group_arn = aws_lb_target_group.frontend.arn
  target_id        = element(aws_instance.frontend.*.id, count.index)
  port             = 80
}

resource "aws_lb_target_group_attachment" "backend" {
  count            = 2
  target_group_arn = aws_lb_target_group.backend.arn
  target_id        = element(aws_instance.backend.*.id, count.index)
  port             = 8080
}

# RDS Instance
resource "aws_db_subnet_group" "main" {
  name       = "main"
  subnet_ids = aws_subnet.private.*.id
}

resource "aws_db_instance" "main" {
  identifier              = "mydbinstance"
  allocated_storage       = 20
  engine                  = "postgres"
  instance_class          = "db.t2.micro"
  name                    = "mydatabase"
  username                = "postgre"
  password                = "root"
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
  db_subnet_group_name    = aws_db_subnet_group.main.name
  multi_az                = true
  publicly_accessible     = false
  skip_final_snapshot     = true
}

# Route 53
resource "aws_route53_record" "frontend" {
  zone_id = var.hosted_zone_id
  name    = "frontend.${var.domain_name}"
  type    = "A"
  alias {
    name                   = aws_lb.frontend.dns_name
    zone_id                = aws_lb.frontend.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "backend" {
  zone_id = var.hosted_zone_id
  name    = "backend.${var.domain_name}"
  type    = "A"
  alias {
    name                   = aws_lb.backend.dns_name
    zone_id                = aws_lb.backend.zone_id
    evaluate_target_health = true
  }
}

# WAF
resource "aws_wafv2_web_acl" "main" {
  name        = "web-acl"
  description = "Web ACL for the application"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "awsCommonRules"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "webACL"
    sampled_requests_enabled   = true
  }
}

resource "aws_wafv2_web_acl_association" "frontend" {
  resource_arn = aws_lb.frontend.arn
  web_acl_arn  = aws_wafv2_web_acl.main.arn
}

resource "aws_wafv2_web_acl_association" "backend" {
  resource_arn = aws_lb.backend.arn
  web_acl_arn  = aws_wafv2_web_acl.main.arn
}

# AWS Backup
resource "aws_backup_vault" "main" {
  name = "main-vault"
}

resource "aws_backup_plan" "main" {
  name = "main-backup-plan"

  rule {
    rule_name         = "daily-backup"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 12 * * ? *)" # Daily at 12 PM UTC

    lifecycle {
      cold_storage_after = 30
      delete_after       = 365
    }
  }
}

resource "aws_backup_selection" "frontend_selection" {
  iam_role_arn = aws_iam_role.main.arn
  name         = "frontend-selection"
  plan_id      = aws_backup_plan.main.id

  resources = [
    aws_instance.frontend[0].arn,
    aws_instance.frontend[1].arn
  ]
}

resource "aws_backup_selection" "backend_selection" {
  iam_role_arn = aws_iam_role.main.arn
  name         = "backend-selection"
  plan_id      = aws_backup_plan.main.id

  resources = [
    aws_instance.backend[0].arn,
    aws_instance.backend[1].arn
  ]
}

# IAM Role for AWS Backup
resource "aws_iam_role" "main" {
  name = "backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "main" {
  role       = aws_iam_role.main.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

output "frontend_alb_dns" {
  value = aws_lb.frontend.dns_name
}

output "backend_alb_dns" {
  value = aws_lb.backend.dns_name
}

output "frontend_url" {
  value = "http://frontend.${var.domain_name}"
}

output "backend_url" {
  value = "http://backend.${var.domain_name}"
}
