output "s3_bucket_id" {
  description = "The name of the bucket."
  value       = resource.aws_s3_bucket.demos3bucket.id
}

output "s3_bucket_arn" {
  description = "The ARN of the bucket"
  value       = resource.aws_s3_bucket.demos3bucket.arn
}