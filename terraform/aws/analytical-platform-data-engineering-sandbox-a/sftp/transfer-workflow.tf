resource "aws_transfer_workflow" "this" {
  description = "Move data from ${var.supplier} landing zone to data store"

  steps {
    tag_step_details {
      name                 = "tag-with-supplier"
      source_file_location = "$${original.file}"
      tags {
        key   = "supplier"
        value = var.supplier
      }
    }
    type = "TAG"
  }
  steps {
    copy_step_details {
      name                 = "copy-file-to-quarantine-bucket"
      source_file_location = "$${original.file}"
      destination_file_location {
        s3_file_location {
          bucket = module.quarantine_bucket.s3_bucket_id
          key    = "${var.supplier}/$${transfer:UserName}/$${transfer:UploadDate}/"
        }
      }
    }
    type = "COPY"
  }
  steps {
    delete_step_details {
      name                 = "delete-file-from-landing-zone"
      source_file_location = "$${original.file}"
    }
    type = "DELETE"
  }

  # TODO: tagging
}

