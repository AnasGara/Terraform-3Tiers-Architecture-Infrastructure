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
