
moved {
  from = aws_vpc.corvanta
  to   = module.network.aws_vpc.corvanta
}

moved {
  from = aws_internet_gateway.corvanta
  to   = module.network.aws_internet_gateway.corvanta
}

moved {
  from = aws_subnet.public
  to   = module.network.aws_subnet.public
}

moved {
  from = aws_subnet.private
  to   = module.network.aws_subnet.private
}

moved {
  from = aws_route_table.public
  to   = module.network.aws_route_table.public
}

moved {
  from = aws_route.public_internet
  to   = module.network.aws_route.public_internet
}

moved {
  from = aws_route_table_association.public
  to   = module.network.aws_route_table_association.public
}

moved {
  from = aws_route_table.private
  to   = module.network.aws_route_table.private
}

moved {
  from = aws_route_table_association.private
  to   = module.network.aws_route_table_association.private
}

moved {
  from = aws_security_group.backend
  to   = module.compute.aws_security_group.backend
}

moved {
  from = aws_key_pair.ec2
  to   = module.compute.aws_key_pair.ec2
}

moved {
  from = aws_instance.backend
  to   = module.compute.aws_instance.backend
}

moved {
  from = aws_eip.backend
  to   = module.compute.aws_eip.backend
}

moved {
  from = aws_eip_association.backend
  to   = module.compute.aws_eip_association.backend
}
