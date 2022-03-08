resource "tls_private_key" "sample-key" {
    algorithm   =  "RSA"
    rsa_bits    =  4096
}
resource "local_file" "private_key" {
    content         =  tls_private_key.sample-key.private_key_pem
    filename        =  "sample-key.pem"
    file_permission =  0400
}
resource "aws_key_pair" "sample-key" {
    key_name   = "sample-key"
    public_key = tls_private_key.sample-key.public_key_openssh
}

resource "aws_security_group" "sg" {
  name        = "sg"
  description = "Security group"
  vpc_id      = local.vpc_id
  ingress {
    description      = "SSH from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = "0.0.0.0"
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "sg"
  }
}

resource "aws_instance" "test" {
  ami                         = "ami-0ddb956ac6be95761"
  key_name                    = aws_key_pair.sample-key.key_name
  instance_type               = "t2.small"
  vpc_security_group_ids      = [aws_security_group.sg.id]
  associate_public_ip_address = true

  root_block_device {
    volume_size           = 50
    delete_on_termination = true
  }

  tags = {
    Name = "sample-ec2"
  }
}


resource "aws_iam_role" "ec2_role" {
  name = "ec2_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ec2-attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.s3policy.arn
}
