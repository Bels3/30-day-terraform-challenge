provider "aws" {
  region = var.region
}

resource "aws_security_group" "web_sg" {
  name        = "terraform-day4-sg"
  description = "Allow HTTP traffic on configurable port"

  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "terraform-day4-sg"
  }
}

resource "aws_instance" "web_server" {
  ami                    = "ami-0c38b837cd80f13bb"
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              cat > index.html <<-HTML
              <!DOCTYPE html>
              <html>
                <head>
                  <title>Beldine | Terraform Day 4</title>
                  <style>
                    body {
                      font-family: Arial, sans-serif;
                      display: flex;
                      justify-content: center;
                      align-items: center;
                      height: 100vh;
                      margin: 0;
                      background: #232f3e;
                      color: white;
                      text-align: center;
                    }
                    h1 { font-size: 2.5em; margin-bottom: 10px; }
                    p  { font-size: 1.2em; color: #ff9900; margin: 5px 0; }
                  </style>
                </head>
                <body>
                  <div>
                    <h1>Beldine's Infrastructure Journey</h1>
                    <p>Day 4 - Configurable Server</p>
                    <p>EveOps | Meru HashiCorp User Group | 30-Day Terraform Challenge</p>
                  </div>
                </body>
              </html>
              HTML
              nohup busybox httpd -f -p ${var.server_port} &
              EOF

  tags = {
    Name = var.server_name
  }
}

output "public_ip" {
  value       = aws_instance.web_server.public_ip
  description = "Public IP of the configurable web server"
}

output "server_port" {
  value       = var.server_port
  description = "Port the server is listening on"
}
