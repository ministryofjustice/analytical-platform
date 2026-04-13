resource "time_sleep" "wait_for_aoss" {

  depends_on = [
    aws_opensearchserverless_collection.vector,
    aws_opensearchserverless_access_policy.data
  ]

  create_duration = "180s"
}

resource "null_resource" "create_index" {
  count = var.skip_index_creation ? 0 : 1

  depends_on = [time_sleep.wait_for_aoss]

  triggers = {
    collection_endpoint = aws_opensearchserverless_collection.vector.collection_endpoint
    index_name          = var.index_name
  }

  provisioner "local-exec" {
    command = <<-EOT
      python3 ${path.module}/scripts/create_index.py \
        --region ${var.region} \
        --endpoint ${aws_opensearchserverless_collection.vector.collection_endpoint} \
        --index-name ${var.index_name} \
        --vector-field ${var.vector_field} \
        --text-field ${var.text_field} \
        --metadata-field ${var.metadata_field} \
        --dimensions ${var.vector_dimensions}
    EOT
  }
}