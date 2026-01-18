# Compute & Storage: EBS, IMDSv2, and Port Security (CIS 5.1.1, 5.1.2, 5.7, 5.3)
# CIS 5.1.1 - Enable EBS encryption by default for the region
resource "aws_ebs_encryption_by_default" "enabled" {
  enabled = true
}

# CIS 5.7 - Enforce IMDSv2
resource "aws_instance" "cis_ec2" {
  instance_type = "t3.micro"

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required" # Forces IMDSv2
  }
}

# CIS 5.3 & 5.1.2 - Restrict Admin Ports (22, 3389) and CIFS (445)
resource "aws_security_group" "restricted_sg" {
  name        = "cis-restricted-sg"
  description = "Block public access to admin/CIFS ports"

  # CIS 5.3: No public SSH/RDP
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"] # Internal only
  }

  # CIS 5.1.2: Restrict CIFS (445)
  ingress {
    from_port   = 445
    to_port     = 445
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"] # Trusted network only
  }
}
