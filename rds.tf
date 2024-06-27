resource "aws_db_subnet_group" "main" {
  name       = "main"
  subnet_ids = aws_subnet.private[*].id
}

resource "aws_db_instance" "main" {
  identifier              = "mydbinstance"
  allocated_storage       = 20
  engine                  = "postgres"
  engine_version          = "12.4"
  instance_class          = "db.t3.micro"
  name                    = "cartoDB"
  username                = "admin"
  password                = "admin123"
  db_subnet_group_name    = aws_db_subnet_group.main.name
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
  skip_final_snapshot     = true
}
