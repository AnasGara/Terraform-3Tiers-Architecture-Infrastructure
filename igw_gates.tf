resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

resource "aws_eip" "nat" {
  count = length(var.admin_subnet_cidrs)
  vpc   = true
}

resource "aws_nat_gateway" "main" {
  count         = length(var.admin_subnet_cidrs)
  allocation_id = element(aws_eip.nat.*.id, count.index)
  subnet_id     = element(aws_subnet.admin.*.id, count.index)
}
