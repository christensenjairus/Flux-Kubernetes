locals {
  manifest_bucket             = "terraform-resources"
  local_manifest_generate_dir = "${path.module}/manifests/generate"
  local_manifest_raw_dir      = "${path.module}/manifests/raw"
  local_manifest_url_dir      = "${path.module}/manifests/presigned-urls"
  presigned_url_expiry        = 3600
}

# Ensure directories exist
resource "null_resource" "create_directories" {
  provisioner "local-exec" {
    command = <<EOT
      mkdir -p ${local.local_manifest_raw_dir}
      mkdir -p ${local.local_manifest_url_dir}
    EOT
  }
}

# --------------------------- Cilium Manifest ---------------------------

# Step 1: Generate Cilium Manifest
resource "null_resource" "generate_cilium_manifest" {
  depends_on = [null_resource.create_directories]

  provisioner "local-exec" {
    command = <<EOT
      ${local.local_manifest_generate_dir}/cilium.sh ${local.cluster_config.networking.cilium.cilium_version} ${local.cluster_config.networking.ipv6.enabled && local.cluster_config.networking.ipv6.dual_stack}
    EOT
  }

  triggers = {
    cilium_version     = local.cluster_config.networking.cilium.cilium_version
    ipv6_enabled       = local.cluster_config.networking.ipv6.enabled
    dual_stack_enabled = local.cluster_config.networking.ipv6.dual_stack
  }
}

# Step 2: Upload Cilium manifest to S3
resource "aws_s3_object" "cilium" {
  depends_on = [null_resource.generate_cilium_manifest]

  bucket = local.manifest_bucket
  key    = "manifests/cilium.yaml"
  source = "${local.local_manifest_raw_dir}/cilium-v${local.cluster_config.networking.cilium.cilium_version}.yaml"
  acl    = "private"
}

# Step 3: Generate pre-signed URL for Cilium manifest
resource "null_resource" "cilium" {
  depends_on = [aws_s3_object.cilium]

  provisioner "local-exec" {
    command = <<EOT
      s3cmd signurl s3://${local.manifest_bucket}/${aws_s3_object.cilium.key} \
      $(( $(date +%s) + ${local.presigned_url_expiry} )) \
      | sed 's|http://|https://|g' \
      > ${local.local_manifest_url_dir}/cilium-v${local.cluster_config.networking.cilium.cilium_version}
    EOT
  }

  triggers = {
    cilium_version     = local.cluster_config.networking.cilium.cilium_version
    ipv6_enabled       = local.cluster_config.networking.ipv6.enabled
    dual_stack_enabled = local.cluster_config.networking.ipv6.dual_stack
  }
}

data "local_file" "cilium" {
  depends_on = [null_resource.cilium]

  filename = "${local.local_manifest_url_dir}/cilium-v${local.cluster_config.networking.cilium.cilium_version}"
}

# --------------------------- Metrics-Server Manifest ---------------------------

# Step 1: Generate Metrics-Server Manifest
resource "null_resource" "generate_metrics_server_manifest" {
  depends_on = [null_resource.create_directories]

  provisioner "local-exec" {
    command = <<EOT
      ${local.local_manifest_generate_dir}/metrics-server.sh ${local.cluster_config.metrics_server.metrics_server_version}
    EOT
  }

  # Trigger re-run if the version changes
  triggers = {
    metrics_server_version = local.cluster_config.metrics_server.metrics_server_version
  }
}

# Step 2: Upload Metrics-Server manifest to S3
resource "aws_s3_object" "metrics_server" {
  depends_on = [null_resource.generate_metrics_server_manifest]

  bucket = local.manifest_bucket
  key    = "manifests/metrics-server.yaml"
  source = "${local.local_manifest_raw_dir}/metrics-server-v${local.cluster_config.metrics_server.metrics_server_version}.yaml"
  acl    = "private"
}

# Step 3: Generate pre-signed URL for Metrics-Server manifest
resource "null_resource" "metrics_server" {
  depends_on = [aws_s3_object.metrics_server]

  provisioner "local-exec" {
    command = <<EOT
      s3cmd signurl s3://${local.manifest_bucket}/${aws_s3_object.metrics_server.key} \
      $(( $(date +%s) + ${local.presigned_url_expiry} )) \
      | sed 's|http://|https://|g' \
      > ${local.local_manifest_url_dir}/metrics-server-v${local.cluster_config.metrics_server.metrics_server_version}
    EOT
  }

  triggers = {
    metrics_server_version = local.cluster_config.metrics_server.metrics_server_version
  }
}

data "local_file" "metrics_server" {
  depends_on = [null_resource.metrics_server]

  filename = "${local.local_manifest_url_dir}/metrics-server-v${local.cluster_config.metrics_server.metrics_server_version}"
}
