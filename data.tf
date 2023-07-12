data "cloudinit_config" "config" {
  gzip          = true
  base64_encode = true
  boundary      = "AZURE"

  part {
    content_type = "text/x-shellscript"
    content      = var.custom_data
  }
}
