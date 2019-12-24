output "web_public_dns" {
  value = aws_instance.web.public_dns
}

output "files_bucket_name" {
  value = aws_s3_bucket.files.bucket
}
