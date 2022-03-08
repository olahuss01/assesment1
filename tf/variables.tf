variable "region" {
    description = "AWS Region"
    default = "us-east-1"
    type = string
}

variable "bucket-suffix" {
    description = "S3 Bucket Name Suffix"
    default = "sam"
    type = string
}

variable "bucket-acl" {
    description = "ACL Value of bucket"
    default = "private"
    type = string
}