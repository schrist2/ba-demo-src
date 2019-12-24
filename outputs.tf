output "web_public_dns" {
  value = aws_instance.web.public_dns
}

output "db_address" {
  value = aws_db_instance.db.endpoint
}

output "files_bucket_name" {
  value = aws_s3_bucket.files.bucket
}
