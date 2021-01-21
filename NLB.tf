# Author - Shaik Minazul Abeddin
# Note in the vaiables.tf you have define access key and secret key to run this terraform script
provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region     = "ap-south-1"
}
# Aws default vpc
resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}
# Aws default subnet
resource "aws_default_subnet" "my-private-default-subnet" {
  availability_zone = "ap-south-1a"

  tags = {
    Name = "my-private-default-subnet"
  }
}
# Aws elatic IP
resource "aws_eip" "eip_nlb" {
  tags = {
    Name = "eip_nlb"
  }
}
# Aws security group with inbound and outbound rules
resource "aws_security_group" "prod-web-servers-sg" {
  name        = "prod-web-servers-sg"
  description = "prod-web-servers-sg"
  tags = {
    Name = "prod-web-servers-sg"
  }
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

  # Aws instance prod-web-server-1
}
resource "aws_instance" "prod-web-server-1" {
  ami                    = "ami-0db0b3ab7df22e366"
  instance_type          = "r5.large"
  availability_zone      = "ap-south-1a"
  subnet_id              = "${aws_default_subnet.my-private-default-subnet.id}"
  vpc_security_group_ids = [aws_security_group.prod-web-servers-sg.id]
  tags = {
    Name = "prod-web-server-1"
  }
}
# Aws instance prod-web-server-2
resource "aws_instance" "prod-web-server-2" {
  ami                    = "ami-0db0b3ab7df22e366"
  instance_type          = "r5.large"
  availability_zone      = "ap-south-1a"
  subnet_id              = "${aws_default_subnet.my-private-default-subnet.id}"
  vpc_security_group_ids = [aws_security_group.prod-web-servers-sg.id]
  tags = {
    Name = "prod-web-server-2"
  }
}
# Aws network loadBalancer
resource "aws_lb" "load_balancer" {
  name               = "network-lb"
  load_balancer_type = "network"
  subnet_mapping {
    subnet_id     = "${aws_default_subnet.my-private-default-subnet.id}"
    allocation_id = "${aws_eip.eip_nlb.id}"
  }
  tags = {
    name = "network-lb"
  }
}
# Aws LoadBalancer listner
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.load_balancer.arn
  port              = "443"
  protocol          = "TCP"
  default_action {
    target_group_arn = "${aws_lb_target_group.tg.arn}"
    type             = "forward"
  }
}
# Aws target group
resource "aws_lb_target_group" "tg" {
  name                 = "tg"
  port                 = "443"
  protocol             = "TCP"
  vpc_id               = "${aws_default_vpc.default.id}"
  target_type          = "instance"
  deregistration_delay = 90
  health_check {
    interval            = 30
    port                = 80
    protocol            = "HTTP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
  tags = {
    name = "tg"
  }
}
# Aws loadbalancer target group attachment for aws prod-web-server-1
resource "aws_lb_target_group_attachment" "tga1" {
  target_group_arn = "${aws_lb_target_group.tg.arn}"
  port             = 80
  target_id        = "${aws_instance.prod-web-server-1.id}"
}
# Aws loadbalancer target group attachment for aws prod-web-server-2
resource "aws_lb_target_group_attachment" "tga2" {
  target_group_arn = "${aws_lb_target_group.tg.arn}"
  port             = 80
  target_id        = "${aws_instance.prod-web-server-2.id}"
}
