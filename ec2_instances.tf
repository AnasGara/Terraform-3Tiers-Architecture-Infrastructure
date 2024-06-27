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
  subnet_id     = element(aws_subnet.private.*.id, count.index + length(aws_subnet.private.*.id) / 2)
  security_groups = [aws_security_group.backend_sg.name]

  tags = {
    Name = "Backend Instance ${count.index + 1}"
  }
}

resource "aws_instance" "admin" {
  ami           = "ami-0c55b159cbfafe1f0" # Amazon Linux 2 AMI (replace with your desired AMI)
  instance_type = "t2.micro"
  subnet_id     = element(aws_subnet.admin.*.id, 0)
  security_groups = [aws_security_group.admin_sg.name]

  tags = {
    Name = "Admin Instance"
  }
}
