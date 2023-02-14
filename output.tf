output "vpc_id" {
  value = module.myvpc.vpc_id
}

output "public_subnet_id" {
  value = module.myvpc.subnet_id
}

output "alb_dns" {
  value = aws_elb.web_alb.dns_name
}