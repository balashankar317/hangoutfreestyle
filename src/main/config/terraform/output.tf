output "hangout_ec2ip" {
  value = aws_instance.hangoutec2.public_ip
}