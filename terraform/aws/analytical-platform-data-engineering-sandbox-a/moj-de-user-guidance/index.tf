resource "null_resource" "create_aoss_index" {
  triggers = {
    collection_endpoint = aws_opensearchserverless_collection.vector.collection_endpoint
    index_name          = var.index_name
    vector_field        = var.vector_field
    text_field          = var.text_field
    metadata_field      = var.metadata_field
    dimensions          = tostring(var.vector_dimensions)
    region              = var.region
  }

  provisioner "local-exec" {
    command = <<EOT
python3 scripts/create_index.py \
  --region ${var.region} \
  --endpoint ${aws_opensearchserverless_collection.vector.collection_endpoint} \
  --index-name ${var.index_name} \
  --vector-field ${var.vector_field} \
  --text-field ${var.text_field} \
  --metadata-field ${var.metadata_field} \
  --dimensions ${var.vector_dimensions}
EOT
  }

  depends_on = [
    aws_opensearchserverless_access_policy.data
  ]
}