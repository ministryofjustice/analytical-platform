resource "aws_launch_template" "dev_standard" {
  name          = "dev_standard"
  image_id      = "ami-0aa9fe9eb35cf4eaf"
  instance_type = "t3a.large"

  disable_api_stop        = false
  disable_api_termination = false

  security_group_names = []

  user_data = "TUlNRS1WZXJzaW9uOiAxLjAKQ29udGVudC1UeXBlOiBtdWx0aXBhcnQvbWl4ZWQ7IGJvdW5kYXJ5PSIvLyIKCi0tLy8KQ29udGVudC1UeXBlOiB0ZXh0L3gtc2hlbGxzY3JpcHQ7IGNoYXJzZXQ9InVzLWFzY2lpIgojIS9iaW4vYmFzaApzZXQgLWV4CkI2NF9DTFVTVEVSX0NBPUxTMHRMUzFDUlVkSlRpQkRSVkpVU1VaSlEwRlVSUzB0TFMwdENrMUpTVU0xZWtORFFXTXJaMEYzU1VKQlowbENRVVJCVGtKbmEzRm9hMmxIT1hjd1FrRlJjMFpCUkVGV1RWSk5kMFZSV1VSV1VWRkVSWGR3Y21SWFNtd0tZMjAxYkdSSFZucE5RalJZUkZSSmVVMUVUWGxOYWtVMFRrUlJlRTR4YjFoRVZFMTVUVVJOZUU5VVJUUk9SRkY0VGpGdmQwWlVSVlJOUWtWSFFURlZSUXBCZUUxTFlUTldhVnBZU25WYVdGSnNZM3BEUTBGVFNYZEVVVmxLUzI5YVNXaDJZMDVCVVVWQ1FsRkJSR2RuUlZCQlJFTkRRVkZ2UTJkblJVSkJUWGhQQ25sMmFFMXdaalJaU2pNMWFHWmFPSE5sVlhNd016UjJja0pWYTI1d2VHZEROR0pIVm5VNWRUTXdlamRYU3lzeWIyazVWRlYyV2pWb1N6RjRWaXRDY1VvS1FuZFNVRmx3Vmtnd1VISlFVakJZWlVKcFMzWnJUVE51TjBwbFNHOHJXWG94WlhsMU9XSlhlR2htYkhocWIyNVhiMUZNVGxCR05FVmtVV2N5UjNkSU1RcHdiRXd5Tm13eVowczBWelZZY0VSUlpWTkpWMVZzVVZGbWJXRTJOVzR6ZDBkbGJHdHRkVXB5U3pKcU1rSkVaRUZDSzJwTVJHWnpWMm94U0dseVRsQkJDa2RsT0dwUmFtOXpSV0Y1YlVWV1FUUTRkM1U0VUV4UU5VWkNlbXBuUjJWTmQyeGFMek5XV0VSNVlWTmFNM3BHZURoSWRGaEJOVXRITkhNM1JrNU9NRWtLYVdGUGJURk5jMWcwVFdOeFMxQkZRVTFYYkRSMVJVTjJhVGw1UTJkWGJVdEVSVTVCVms5SFRGVnZUR2MwYzI4eVpWUm9MM013ZVVKSlYwc3ZkRzB5VlFwbmJUVkxhbTVNYkZCclltUkVSMjVWTTBORlEwRjNSVUZCWVU1RFRVVkJkMFJuV1VSV1VqQlFRVkZJTDBKQlVVUkJaMHRyVFVFNFIwRXhWV1JGZDBWQ0NpOTNVVVpOUVUxQ1FXWTRkMGhSV1VSV1VqQlBRa0paUlVaSlNrMVZiVU5VUzJwdGIwaHVNeTkwZGsxT01tdHNaVVV2UzI1TlFUQkhRMU54UjFOSllqTUtSRkZGUWtOM1ZVRkJORWxDUVZGQ2VreEZRMDlOZVd4WmFtZzBlakJ1T1dwR09UaEVVR2hvYW5CcGVqSlBUVkZ4Y0cxYVFuZE5WMjlVVEZWRFdtUkdTQXBLV1dwRFFuQjZSM1JPUTFSeFpETm5VSGxRUTFsS2RtdDZiemh4UjBoWWNWVkJUakpJUm14NFNUZ3pSSEE1V0ZoTVNFeFFWaXRxWVdSUVNXaG1hWGhJQ25GVFFrdElUekJOU3k4eVRWcHJPVkY2YzJORlNuTXpkazFrU21KeFpIZ3ZXV2QzTUhKWGRFNUxTRzFvV0V4dllrcHFLMUJvVHpaUlkyWlhSeXNyVFdrS1RtRTJNMjh6WmtRelJFdEtPRVp5Um10VmNGbEZRazAwVm0xbE5FeHJTVGhCVml0Rk5YQlZVR3huTUdsQ1pIZDNUSGhWTTBGMkx6UkdjbU5tZDFVNWNRcE1abWx3YlVseVMyb3daR2QwYjFvdmJXMTBXV0p5THpZNVVFdHJiU3QzVldkelNqQlBOMmc1Ym05R2RURTROMVpOWjJVM2NrazFhRVoxUTNOV1MzTllDaloxV0VwRVQwdHFWREV3Vm5wSmNtSnNibFpxSzA1WGVWcFJNM2x2TkRrd1YwODROQW90TFMwdExVVk9SQ0JEUlZKVVNVWkpRMEZVUlMwdExTMHRDZz09CkFQSV9TRVJWRVJfVVJMPWh0dHBzOi8vNTk0Mjk0MjhFQkFCQkI5RjkxMUExNzNEN0I4RTgxNzkuZ3I3LmV1LXdlc3QtMS5la3MuYW1hem9uYXdzLmNvbQpLOFNfQ0xVU1RFUl9ETlNfSVA9MTcyLjIwLjAuMTAKL2V0Yy9la3MvYm9vdHN0cmFwLnNoIGFpcmZsb3ctZGV2IC0ta3ViZWxldC1leHRyYS1hcmdzICctLW5vZGUtbGFiZWxzPWVrcy5hbWF6b25hd3MuY29tL25vZGVncm91cC1pbWFnZT1hbWktMGFhOWZlOWViMzVjZjRlYWYsZWtzLmFtYXpvbmF3cy5jb20vY2FwYWNpdHlUeXBlPVNQT1QsZWtzLmFtYXpvbmF3cy5jb20vbm9kZWdyb3VwPXN0YW5kYXJkIC0tbWF4LXBvZHM9MzUnIC0tYjY0LWNsdXN0ZXItY2EgJEI2NF9DTFVTVEVSX0NBIC0tYXBpc2VydmVyLWVuZHBvaW50ICRBUElfU0VSVkVSX1VSTCAtLWRucy1jbHVzdGVyLWlwICRLOFNfQ0xVU1RFUl9ETlNfSVAgLS11c2UtbWF4LXBvZHMgZmFsc2UKCi0tLy8tLQ=="

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      delete_on_termination = "true"
      iops                  = 3000
      throughput            = 250
      volume_size           = 150
      volume_type           = "gp3"
    }
  }

  metadata_options {
    http_put_response_hop_limit = 2
    http_tokens                 = "optional"
  }

  network_interfaces {
    device_index       = 0
    ipv4_address_count = 0
    ipv4_addresses     = []
    ipv4_prefix_count  = 0
    ipv4_prefixes      = []
    ipv6_address_count = 0
    ipv6_addresses     = []
    ipv6_prefix_count  = 0
    ipv6_prefixes      = []
    network_card_index = 0
    security_groups = [
      "sg-089008308707d83b7"
    ]
  }

  tags = {
    "eks:cluster-name"                                       = "airflow-dev"
    "eks:nodegroup-name"                                     = "standard"
    "k8s.io/cluster-autoscaler/node-template/label/standard" = "true"
    "k8s.io/cluster-autoscaler/node-template/taint/standard" = "true:NoSchedule"
  }
}

resource "aws_launch_template" "dev_high_memory" {
  name          = "dev_high_memory"
  image_id      = "ami-03857889452e262ff"
  instance_type = "r6i.8xlarge"

  disable_api_stop        = false
  disable_api_termination = false

  security_group_names = []

  user_data = "TUlNRS1WZXJzaW9uOiAxLjAKQ29udGVudC1UeXBlOiBtdWx0aXBhcnQvbWl4ZWQ7IGJvdW5kYXJ5PSIvLyIKCi0tLy8KQ29udGVudC1UeXBlOiB0ZXh0L3gtc2hlbGxzY3JpcHQ7IGNoYXJzZXQ9InVzLWFzY2lpIgojIS9iaW4vYmFzaApzZXQgLWV4CkI2NF9DTFVTVEVSX0NBPUxTMHRMUzFDUlVkSlRpQkRSVkpVU1VaSlEwRlVSUzB0TFMwdENrMUpTVU0xZWtORFFXTXJaMEYzU1VKQlowbENRVVJCVGtKbmEzRm9hMmxIT1hjd1FrRlJjMFpCUkVGV1RWSk5kMFZSV1VSV1VWRkVSWGR3Y21SWFNtd0tZMjAxYkdSSFZucE5RalJZUkZSSmVVMUVUWGxOYWtVMFRrUlJlRTR4YjFoRVZFMTVUVVJOZUU5VVJUUk9SRkY0VGpGdmQwWlVSVlJOUWtWSFFURlZSUXBCZUUxTFlUTldhVnBZU25WYVdGSnNZM3BEUTBGVFNYZEVVVmxLUzI5YVNXaDJZMDVCVVVWQ1FsRkJSR2RuUlZCQlJFTkRRVkZ2UTJkblJVSkJUWGhQQ25sMmFFMXdaalJaU2pNMWFHWmFPSE5sVlhNd016UjJja0pWYTI1d2VHZEROR0pIVm5VNWRUTXdlamRYU3lzeWIyazVWRlYyV2pWb1N6RjRWaXRDY1VvS1FuZFNVRmx3Vmtnd1VISlFVakJZWlVKcFMzWnJUVE51TjBwbFNHOHJXWG94WlhsMU9XSlhlR2htYkhocWIyNVhiMUZNVGxCR05FVmtVV2N5UjNkSU1RcHdiRXd5Tm13eVowczBWelZZY0VSUlpWTkpWMVZzVVZGbWJXRTJOVzR6ZDBkbGJHdHRkVXB5U3pKcU1rSkVaRUZDSzJwTVJHWnpWMm94U0dseVRsQkJDa2RsT0dwUmFtOXpSV0Y1YlVWV1FUUTRkM1U0VUV4UU5VWkNlbXBuUjJWTmQyeGFMek5XV0VSNVlWTmFNM3BHZURoSWRGaEJOVXRITkhNM1JrNU9NRWtLYVdGUGJURk5jMWcwVFdOeFMxQkZRVTFYYkRSMVJVTjJhVGw1UTJkWGJVdEVSVTVCVms5SFRGVnZUR2MwYzI4eVpWUm9MM013ZVVKSlYwc3ZkRzB5VlFwbmJUVkxhbTVNYkZCclltUkVSMjVWTTBORlEwRjNSVUZCWVU1RFRVVkJkMFJuV1VSV1VqQlFRVkZJTDBKQlVVUkJaMHRyVFVFNFIwRXhWV1JGZDBWQ0NpOTNVVVpOUVUxQ1FXWTRkMGhSV1VSV1VqQlBRa0paUlVaSlNrMVZiVU5VUzJwdGIwaHVNeTkwZGsxT01tdHNaVVV2UzI1TlFUQkhRMU54UjFOSllqTUtSRkZGUWtOM1ZVRkJORWxDUVZGQ2VreEZRMDlOZVd4WmFtZzBlakJ1T1dwR09UaEVVR2hvYW5CcGVqSlBUVkZ4Y0cxYVFuZE5WMjlVVEZWRFdtUkdTQXBLV1dwRFFuQjZSM1JPUTFSeFpETm5VSGxRUTFsS2RtdDZiemh4UjBoWWNWVkJUakpJUm14NFNUZ3pSSEE1V0ZoTVNFeFFWaXRxWVdSUVNXaG1hWGhJQ25GVFFrdElUekJOU3k4eVRWcHJPVkY2YzJORlNuTXpkazFrU21KeFpIZ3ZXV2QzTUhKWGRFNUxTRzFvV0V4dllrcHFLMUJvVHpaUlkyWlhSeXNyVFdrS1RtRTJNMjh6WmtRelJFdEtPRVp5Um10VmNGbEZRazAwVm0xbE5FeHJTVGhCVml0Rk5YQlZVR3huTUdsQ1pIZDNUSGhWTTBGMkx6UkdjbU5tZDFVNWNRcE1abWx3YlVseVMyb3daR2QwYjFvdmJXMTBXV0p5THpZNVVFdHJiU3QzVldkelNqQlBOMmc1Ym05R2RURTROMVpOWjJVM2NrazFhRVoxUTNOV1MzTllDaloxV0VwRVQwdHFWREV3Vm5wSmNtSnNibFpxSzA1WGVWcFJNM2x2TkRrd1YwODROQW90TFMwdExVVk9SQ0JEUlZKVVNVWkpRMEZVUlMwdExTMHRDZz09CkFQSV9TRVJWRVJfVVJMPWh0dHBzOi8vNTk0Mjk0MjhFQkFCQkI5RjkxMUExNzNEN0I4RTgxNzkuZ3I3LmV1LXdlc3QtMS5la3MuYW1hem9uYXdzLmNvbQpLOFNfQ0xVU1RFUl9ETlNfSVA9MTcyLjIwLjAuMTAKL2V0Yy9la3MvYm9vdHN0cmFwLnNoIGFpcmZsb3ctZGV2IC0ta3ViZWxldC1leHRyYS1hcmdzICctLW5vZGUtbGFiZWxzPWVrcy5hbWF6b25hd3MuY29tL25vZGVncm91cC1pbWFnZT1hbWktMDYwZmE1MjZkZTA1MjFjMDcsZWtzLmFtYXpvbmF3cy5jb20vY2FwYWNpdHlUeXBlPU9OX0RFTUFORCxoaWdoLW1lbW9yeT10cnVlLGVrcy5hbWF6b25hd3MuY29tL25vZGVncm91cD1oaWdoLW1lbW9yeSAtLXJlZ2lzdGVyLXdpdGgtdGFpbnRzPWhpZ2gtbWVtb3J5PXRydWU6Tm9TY2hlZHVsZSAtLW1heC1wb2RzPTIzNCcgLS1iNjQtY2x1c3Rlci1jYSAkQjY0X0NMVVNURVJfQ0EgLS1hcGlzZXJ2ZXItZW5kcG9pbnQgJEFQSV9TRVJWRVJfVVJMIC0tZG5zLWNsdXN0ZXItaXAgJEs4U19DTFVTVEVSX0ROU19JUCAtLXVzZS1tYXgtcG9kcyBmYWxzZQoKLS0vLy0t"

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      delete_on_termination = "true"
      iops                  = 3000
      throughput            = 250
      volume_size           = 200
      volume_type           = "gp3"
    }
  }

  metadata_options {
    http_put_response_hop_limit = 2
    http_tokens                 = "optional"
  }

  network_interfaces {
    device_index       = 0
    ipv4_address_count = 0
    ipv4_addresses     = []
    ipv4_prefix_count  = 0
    ipv4_prefixes      = []
    ipv6_address_count = 0
    ipv6_addresses     = []
    ipv6_prefix_count  = 0
    ipv6_prefixes      = []
    network_card_index = 0
    security_groups = [
      "sg-089008308707d83b7"
    ]
  }

  tags = {
    "eks:cluster-name"                                          = "airflow-dev"
    "eks:nodegroup-name"                                        = "high-memory"
    "k8s.io/cluster-autoscaler/node-template/label/high-memory" = "true"
    "k8s.io/cluster-autoscaler/node-template/taint/high-memory" = "true:NoSchedule"
  }
}

resource "aws_launch_template" "sandpit_standard" {
  name          = "eks-dcc306aa-0520-d4e7-1ef0-b26027ceb6da"
  image_id      = "ami-0aa9fe9eb35cf4eaf"
  instance_type = "t3a.small"

  disable_api_stop        = false
  disable_api_termination = false

  security_group_names = []

  user_data = "TUlNRS1WZXJzaW9uOiAxLjAKQ29udGVudC1UeXBlOiBtdWx0aXBhcnQvbWl4ZWQ7IGJvdW5kYXJ5PSIvLyIKCi0tLy8KQ29udGVudC1UeXBlOiB0ZXh0L3gtc2hlbGxzY3JpcHQ7IGNoYXJzZXQ9InVzLWFzY2lpIgojIS9iaW4vYmFzaApzZXQgLWV4CkI2NF9DTFVTVEVSX0NBPUxTMHRMUzFDUlVkSlRpQkRSVkpVU1VaSlEwRlVSUzB0TFMwdENrMUpTVU12YWtORFFXVmhaMEYzU1VKQlowbENRVVJCVGtKbmEzRm9hMmxIT1hjd1FrRlJjMFpCUkVGV1RWSk5kMFZSV1VSV1VWRkVSWGR3Y21SWFNtd0tZMjAxYkdSSFZucE5RalJZUkZSSmVrMUVTWGROVkVVd1RWUkJlRTFXYjFoRVZFMTZUVVJGZVU5VVJUQk5WRUY0VFZadmQwWlVSVlJOUWtWSFFURlZSUXBCZUUxTFlUTldhVnBZU25WYVdGSnNZM3BEUTBGVFNYZEVVVmxLUzI5YVNXaDJZMDVCVVVWQ1FsRkJSR2RuUlZCQlJFTkRRVkZ2UTJkblJVSkJURzFIQ2tsWk1IUXpRVGxFUlc1blRtVklLMk16ZURWcmNURlNMMGRqUTBKaFQwSTVlRTh2ZUdaTVZVRnhSazFvY21sME5XZDBkVFZVT0VsTGMzVTVOR2hLVUM4S1ZtazBZVkpYV2xweksxVjFTa1l5WjFCU1ZsUjZORk54UVc5ck5qY3JkbmxMUkRCVE9XTkJlREpSTTBORlV6SlJTbTVKWlZCNllYQjZVakZ2T1VwMFJBbzNjV3hoZDNsTVNrcEdVMmhUVFdkeVdWZ3hOVTlXUzBOQ1VITktjWGt4YXpkQlRYWXplamxQZEZGSFlXUmlUMlp2ZVRKSE5VRkhWRnAyVlRRM01tNVJDbGxYYUc4MFVFbGFaMmREUWtGbVNFZENVMGRwSzNsbGJpOXhLM3BaUVRkd2VXRnRhVmRvUXpCRmMwbzViRGREV1Rad2RIaGxMMmhuUVZGRk9XUjVVMGtLSzFGck9XSk5kRlZvYW1OdE0zYzNiM1p0U0N0UGRtaGxaMjB4UzFaMmJGUlJjVW8zT0V0VGIyTTNkM0ZxYkN0d1prOWlUbVp2TjBkTU1WUm9UVE5LUVFwMmVYazBTVXc0YUZnMGRXazFXbFZEUlVFd1EwRjNSVUZCWVU1YVRVWmpkMFJuV1VSV1VqQlFRVkZJTDBKQlVVUkJaMHRyVFVFNFIwRXhWV1JGZDBWQ0NpOTNVVVpOUVUxQ1FXWTRkMGhSV1VSV1VqQlBRa0paUlVaRVN5OVhMMUVyYXpsMVIxcG5jMGcwVG5nMFkxWTBWakJSZUVoTlFsVkhRVEZWWkVWUlVVOEtUVUY1UTBOdGRERlpiVlo1WW0xV01GcFlUWGRFVVZsS1MyOWFTV2gyWTA1QlVVVk1RbEZCUkdkblJVSkJSbXN4TmpKblZVWkRNRmR2YlVsMk5rOW5kQXBtWldoUFFUTjFkbEZhTjBWNU1VVjVhMUV5VFVjeGFXbHFaVmRJTUZOSVUxSlFhak16Y1RCWlZqSk5jbGhyUWxCT2FuUnlZbkJXYURSMWVWVjZLMHh6Q25WNlRYaDZWek5wYVZkVmRrVlFZV3Q1VVRaRk4zTlRTRVIxV1ZZeGFGb3ZiRVZXTVVOUVFXdDVUbFpTYzJGdFp6UXpjbnB6UzJGQk4xTktORlJNVTJjS2RpOVJWa2hvYm01WGNXeENUalJhUVc1eFQyeDVRM053VlZObFRHdE9WRloxYzNOU1dqUkxTRUZyVDFZNEszTkxNR3BMVEhwbVV6VjNlVkEwTXpGWFRncG1LMk5YVDB0V1NHSXZiV01yT1dSMVYzRlJaRTFuTVdWUVUzQnVNVEUwWTNvMVp6WkNiRGxRV2tZd05tMVpRMUZ1YWxORWR6STVURUpZWkc5NlJ5OUJDbnB6TlVOYVYwdG5NMUI0V25sV2JVWXhZaXN2Y2pGWlVIRmtlVlZEV2pGd1oyRnJWRzQ0VjBZMVJGWTJZMnhxYUZOb1ptTkZWRGgxUkdsWE1YWTJOa2NLTHpCblBRb3RMUzB0TFVWT1JDQkRSVkpVU1VaSlEwRlVSUzB0TFMwdENnPT0KQVBJX1NFUlZFUl9VUkw9aHR0cHM6Ly9CQkY2QTNDRkE2RkY1N0IxOTExRjU4RDAzN0VEM0Y1NC5ncjcuZXUtd2VzdC0xLmVrcy5hbWF6b25hd3MuY29tCks4U19DTFVTVEVSX0ROU19JUD0xNzIuMjAuMC4xMAovZXRjL2Vrcy9ib290c3RyYXAuc2ggYWlyZmxvdy1zYW5kcGl0IC0ta3ViZWxldC1leHRyYS1hcmdzICctLW5vZGUtbGFiZWxzPWVrcy5hbWF6b25hd3MuY29tL25vZGVncm91cC1pbWFnZT1hbWktMGFhOWZlOWViMzVjZjRlYWYsZWtzLmFtYXpvbmF3cy5jb20vY2FwYWNpdHlUeXBlPVNQT1QsZWtzLmFtYXpvbmF3cy5jb20vbm9kZWdyb3VwPXN0YW5kYXJkIC0tbWF4LXBvZHM9OCcgLS1iNjQtY2x1c3Rlci1jYSAkQjY0X0NMVVNURVJfQ0EgLS1hcGlzZXJ2ZXItZW5kcG9pbnQgJEFQSV9TRVJWRVJfVVJMIC0tZG5zLWNsdXN0ZXItaXAgJEs4U19DTFVTVEVSX0ROU19JUCAtLXVzZS1tYXgtcG9kcyBmYWxzZQoKLS0vLy0t"

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      delete_on_termination = "true"
      iops                  = 0
      throughput            = 125
      volume_size           = 20
      volume_type           = "gp2"
    }
  }

  iam_instance_profile {
    name = "eks-dcc306aa-0520-d4e7-1ef0-b26027ceb6da"
  }

  metadata_options {
    http_put_response_hop_limit = 2
    http_tokens                 = "optional"
  }

  network_interfaces {
    device_index       = 0
    ipv4_address_count = 0
    ipv4_addresses     = []
    ipv4_prefix_count  = 0
    ipv4_prefixes      = []
    ipv6_address_count = 0
    ipv6_addresses     = []
    ipv6_prefix_count  = 0
    ipv6_prefixes      = []
    network_card_index = 0
    security_groups = [
      "sg-0aa6fbd5f564dc793"
    ]
  }

  tags = {
    "eks:cluster-name"   = "airflow-sandpit"
    "eks:nodegroup-name" = "standard"
  }
}

resource "aws_launch_template" "sandpit_high_memory" {
  name          = "eks-50c306aa-05d8-6b86-cfe1-6007657b8987"
  image_id      = "ami-0aa9fe9eb35cf4eaf"
  instance_type = "r6i.4xlarge"

  disable_api_stop        = false
  disable_api_termination = false

  security_group_names = []

  user_data = "TUlNRS1WZXJzaW9uOiAxLjAKQ29udGVudC1UeXBlOiBtdWx0aXBhcnQvbWl4ZWQ7IGJvdW5kYXJ5PSIvLyIKCi0tLy8KQ29udGVudC1UeXBlOiB0ZXh0L3gtc2hlbGxzY3JpcHQ7IGNoYXJzZXQ9InVzLWFzY2lpIgojIS9iaW4vYmFzaApzZXQgLWV4CkI2NF9DTFVTVEVSX0NBPUxTMHRMUzFDUlVkSlRpQkRSVkpVU1VaSlEwRlVSUzB0TFMwdENrMUpTVU12YWtORFFXVmhaMEYzU1VKQlowbENRVVJCVGtKbmEzRm9hMmxIT1hjd1FrRlJjMFpCUkVGV1RWSk5kMFZSV1VSV1VWRkVSWGR3Y21SWFNtd0tZMjAxYkdSSFZucE5RalJZUkZSSmVrMUVTWGROVkVVd1RWUkJlRTFXYjFoRVZFMTZUVVJGZVU5VVJUQk5WRUY0VFZadmQwWlVSVlJOUWtWSFFURlZSUXBCZUUxTFlUTldhVnBZU25WYVdGSnNZM3BEUTBGVFNYZEVVVmxLUzI5YVNXaDJZMDVCVVVWQ1FsRkJSR2RuUlZCQlJFTkRRVkZ2UTJkblJVSkJURzFIQ2tsWk1IUXpRVGxFUlc1blRtVklLMk16ZURWcmNURlNMMGRqUTBKaFQwSTVlRTh2ZUdaTVZVRnhSazFvY21sME5XZDBkVFZVT0VsTGMzVTVOR2hLVUM4S1ZtazBZVkpYV2xweksxVjFTa1l5WjFCU1ZsUjZORk54UVc5ck5qY3JkbmxMUkRCVE9XTkJlREpSTTBORlV6SlJTbTVKWlZCNllYQjZVakZ2T1VwMFJBbzNjV3hoZDNsTVNrcEdVMmhUVFdkeVdWZ3hOVTlXUzBOQ1VITktjWGt4YXpkQlRYWXplamxQZEZGSFlXUmlUMlp2ZVRKSE5VRkhWRnAyVlRRM01tNVJDbGxYYUc4MFVFbGFaMmREUWtGbVNFZENVMGRwSzNsbGJpOXhLM3BaUVRkd2VXRnRhVmRvUXpCRmMwbzViRGREV1Rad2RIaGxMMmhuUVZGRk9XUjVVMGtLSzFGck9XSk5kRlZvYW1OdE0zYzNiM1p0U0N0UGRtaGxaMjB4UzFaMmJGUlJjVW8zT0V0VGIyTTNkM0ZxYkN0d1prOWlUbVp2TjBkTU1WUm9UVE5LUVFwMmVYazBTVXc0YUZnMGRXazFXbFZEUlVFd1EwRjNSVUZCWVU1YVRVWmpkMFJuV1VSV1VqQlFRVkZJTDBKQlVVUkJaMHRyVFVFNFIwRXhWV1JGZDBWQ0NpOTNVVVpOUVUxQ1FXWTRkMGhSV1VSV1VqQlBRa0paUlVaRVN5OVhMMUVyYXpsMVIxcG5jMGcwVG5nMFkxWTBWakJSZUVoTlFsVkhRVEZWWkVWUlVVOEtUVUY1UTBOdGRERlpiVlo1WW0xV01GcFlUWGRFVVZsS1MyOWFTV2gyWTA1QlVVVk1RbEZCUkdkblJVSkJSbXN4TmpKblZVWkRNRmR2YlVsMk5rOW5kQXBtWldoUFFUTjFkbEZhTjBWNU1VVjVhMUV5VFVjeGFXbHFaVmRJTUZOSVUxSlFhak16Y1RCWlZqSk5jbGhyUWxCT2FuUnlZbkJXYURSMWVWVjZLMHh6Q25WNlRYaDZWek5wYVZkVmRrVlFZV3Q1VVRaRk4zTlRTRVIxV1ZZeGFGb3ZiRVZXTVVOUVFXdDVUbFpTYzJGdFp6UXpjbnB6UzJGQk4xTktORlJNVTJjS2RpOVJWa2hvYm01WGNXeENUalJhUVc1eFQyeDVRM053VlZObFRHdE9WRloxYzNOU1dqUkxTRUZyVDFZNEszTkxNR3BMVEhwbVV6VjNlVkEwTXpGWFRncG1LMk5YVDB0V1NHSXZiV01yT1dSMVYzRlJaRTFuTVdWUVUzQnVNVEUwWTNvMVp6WkNiRGxRV2tZd05tMVpRMUZ1YWxORWR6STVURUpZWkc5NlJ5OUJDbnB6TlVOYVYwdG5NMUI0V25sV2JVWXhZaXN2Y2pGWlVIRmtlVlZEV2pGd1oyRnJWRzQ0VjBZMVJGWTJZMnhxYUZOb1ptTkZWRGgxUkdsWE1YWTJOa2NLTHpCblBRb3RMUzB0TFVWT1JDQkRSVkpVU1VaSlEwRlVSUzB0TFMwdENnPT0KQVBJX1NFUlZFUl9VUkw9aHR0cHM6Ly9CQkY2QTNDRkE2RkY1N0IxOTExRjU4RDAzN0VEM0Y1NC5ncjcuZXUtd2VzdC0xLmVrcy5hbWF6b25hd3MuY29tCks4U19DTFVTVEVSX0ROU19JUD0xNzIuMjAuMC4xMAovZXRjL2Vrcy9ib290c3RyYXAuc2ggYWlyZmxvdy1zYW5kcGl0IC0ta3ViZWxldC1leHRyYS1hcmdzICctLW5vZGUtbGFiZWxzPWVrcy5hbWF6b25hd3MuY29tL25vZGVncm91cC1pbWFnZT1hbWktMGFhOWZlOWViMzVjZjRlYWYsZWtzLmFtYXpvbmF3cy5jb20vY2FwYWNpdHlUeXBlPVNQT1QsaGlnaC1tZW1vcnk9dHJ1ZSxla3MuYW1hem9uYXdzLmNvbS9ub2RlZ3JvdXA9aGlnaC1tZW1vcnkgLS1yZWdpc3Rlci13aXRoLXRhaW50cz1oaWdoLW1lbW9yeT10cnVlOk5vU2NoZWR1bGUgLS1tYXgtcG9kcz0xMTAnIC0tYjY0LWNsdXN0ZXItY2EgJEI2NF9DTFVTVEVSX0NBIC0tYXBpc2VydmVyLWVuZHBvaW50ICRBUElfU0VSVkVSX1VSTCAtLWRucy1jbHVzdGVyLWlwICRLOFNfQ0xVU1RFUl9ETlNfSVAgLS11c2UtbWF4LXBvZHMgZmFsc2UKCi0tLy8tLQ=="

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      delete_on_termination = "true"
      iops                  = 0
      throughput            = 125
      volume_size           = 20
      volume_type           = "gp2"
    }
  }

  iam_instance_profile {
    name = "eks-50c306aa-05d8-6b86-cfe1-6007657b8987"
  }

  metadata_options {
    http_put_response_hop_limit = 2
    http_tokens                 = "optional"
  }

  network_interfaces {
    device_index       = 0
    ipv4_address_count = 0
    ipv4_addresses     = []
    ipv4_prefix_count  = 0
    ipv4_prefixes      = []
    ipv6_address_count = 0
    ipv6_addresses     = []
    ipv6_prefix_count  = 0
    ipv6_prefixes      = []
    network_card_index = 0
    security_groups = [
      "sg-0aa6fbd5f564dc793"
    ]
  }

  tags = {
    "eks:cluster-name"   = "airflow-sandpit"
    "eks:nodegroup-name" = "high-memory"
  }
}

resource "aws_launch_template" "prod_standard" {
  name          = "prod_standard"
  image_id      = "ami-03857889452e262ff"
  instance_type = "t3a.large"

  disable_api_stop        = false
  disable_api_termination = false

  security_group_names = []

  user_data = "TUlNRS1WZXJzaW9uOiAxLjAKQ29udGVudC1UeXBlOiBtdWx0aXBhcnQvbWl4ZWQ7IGJvdW5kYXJ5PSIvLyIKCi0tLy8KQ29udGVudC1UeXBlOiB0ZXh0L3gtc2hlbGxzY3JpcHQ7IGNoYXJzZXQ9InVzLWFzY2lpIgojIS9iaW4vYmFzaApzZXQgLWV4CkI2NF9DTFVTVEVSX0NBPUxTMHRMUzFDUlVkSlRpQkRSVkpVU1VaSlEwRlVSUzB0TFMwdENrMUpTVU0xZWtORFFXTXJaMEYzU1VKQlowbENRVVJCVGtKbmEzRm9hMmxIT1hjd1FrRlJjMFpCUkVGV1RWSk5kMFZSV1VSV1VWRkVSWGR3Y21SWFNtd0tZMjAxYkdSSFZucE5RalJZUkZSSmVVMUVUWGxOVkVVelRYcEJlVTVXYjFoRVZFMTVUVVJOZUU5RVJUTk5la0Y1VGxadmQwWlVSVlJOUWtWSFFURlZSUXBCZUUxTFlUTldhVnBZU25WYVdGSnNZM3BEUTBGVFNYZEVVVmxLUzI5YVNXaDJZMDVCVVVWQ1FsRkJSR2RuUlZCQlJFTkRRVkZ2UTJkblJVSkJTMVJVQ21acGRFUnJkRFUxY0RkYWFrcFBWMFo1YVRsdk0ySmpWV1pUTURGTWRWZG9hbUpYU1dabVlWQlRjR1JDVldkRmNVeFVjMk5TWjNveFZUVTFhRzF1Y25vS09ERldiblZtU2pnMk5UWnZSbTQ1WlhsMlVIUlFibFp2VTJkNk9EQmhjVTQ1VkZkaVJYTnVXR1ZDYVRsaFVXUlBiRmRoUTI1dEsyWk1kMEZGU21KbEt3bzBOM1UzV1cxSVRqbElUbE5hWVVSdFFTOVhkRmhTYzNNNU9GVmFWVXhhZGk5WlRuZ3phWGhuSzBOV1NXTlNheTl0VUZWVlZEVTJjbXhZSzI1S1NEUTBDbVF2ZUd4UFRXaE9iR3RCZFZWb2JtSnFOR016U1hoRmQxcDNlWGRYZVZOcGFXVk9ia1UyVFZsT2VrWnpiaTh3TVU5eVUwSjNSRzlWV0doaWVsaEpaR2tLVm5kR1VGaGFLMDg0VDNobFMzVkdNbnBzVFZsQ1UwUkVTV2hQTm0xMlowZHJTRGhXYWxWVlpUWXJhWGxOVFdWaE1GQm5MMGxYTVhWR2R6QjFiSHBVTndwR1dTdHpaRFEzV2s1M01UZE9jalZUU1dWelEwRjNSVUZCWVU1RFRVVkJkMFJuV1VSV1VqQlFRVkZJTDBKQlVVUkJaMHRyVFVFNFIwRXhWV1JGZDBWQ0NpOTNVVVpOUVUxQ1FXWTRkMGhSV1VSV1VqQlBRa0paUlVaTldYTmxjR0ZEZWtWcWEyMVFVbmRXTTNoVE5sbGlORWt6Y3poTlFUQkhRMU54UjFOSllqTUtSRkZGUWtOM1ZVRkJORWxDUVZGQmFqUmxZaTgzU1VNeFVsTlJXa05xZW5CaE5uSkZTV2hVWWxwc01YRTROaXR6TDB0blIwRkliWFlyWlZaQ2FtYzBSZ293WldKSFVFVnpaM05SVERscFNtZG5OMUkxTHpVdk4ydFZibVpEVlZwRlNWcExRMlJhY0ZSMGFrZHVWelJ1Y1hGSVVIY3lhRVUxY3pkRVFVcFNSSEpaQ25BMlVrVTJOemxTT1VWTVZUTm9TbVUxYjB0Uk9XUjFibXR0TWpsUWJWZHBhRzE1V1dzMmFraFlNMDEwVmpndlZqRmtSM0pQZVU0NGEyRkhjMXBKWTBZS1pHOHphMjgwVTJkR1VrOVdkMWR4YVRkTVFraHNWbE16VFRBMU5tdDBjbEpuWTNSMFRtUXZVRkE1VWpSU2IyY3JWalZvWlVOU2NtczFNMjVIZG1GQmR3b3lSRXQyVkhvNVZubHBlakJyWTB0TWFYcHZaREJyYjFwbkwwazFlSFYwWjNsbmRYQk1Za1pTZDFOT056WXhTbXhHU2xvcmFEaEhOVE4zY21OQ1IzcFFDamRyYkZVMVdqSnFVVk5sVTBGUGEwRXZUM3BUYzB4VWFWRTBNRXR4UzJSMVdYQXlUUW90TFMwdExVVk9SQ0JEUlZKVVNVWkpRMEZVUlMwdExTMHRDZz09CkFQSV9TRVJWRVJfVVJMPWh0dHBzOi8vRkMzRjdBODg1MDg2NzZBMzBEQ0FGRTdCMjYxOUI1NDQuZ3I3LmV1LXdlc3QtMS5la3MuYW1hem9uYXdzLmNvbQpLOFNfQ0xVU1RFUl9ETlNfSVA9MTcyLjIwLjAuMTAKL2V0Yy9la3MvYm9vdHN0cmFwLnNoIGFpcmZsb3ctcHJvZCAtLWt1YmVsZXQtZXh0cmEtYXJncyAnLS1ub2RlLWxhYmVscz1la3MuYW1hem9uYXdzLmNvbS9ub2RlZ3JvdXAtaW1hZ2U9YW1pLTAzODU3ODg5NDUyZTI2MmZmLGVrcy5hbWF6b25hd3MuY29tL2NhcGFjaXR5VHlwZT1PTl9ERU1BTkQsZWtzLmFtYXpvbmF3cy5jb20vbm9kZWdyb3VwPXN0YW5kYXJkIC0tbWF4LXBvZHM9MzUnIC0tYjY0LWNsdXN0ZXItY2EgJEI2NF9DTFVTVEVSX0NBIC0tYXBpc2VydmVyLWVuZHBvaW50ICRBUElfU0VSVkVSX1VSTCAtLWRucy1jbHVzdGVyLWlwICRLOFNfQ0xVU1RFUl9ETlNfSVAgLS11c2UtbWF4LXBvZHMgZmFsc2UKCi0tLy8tLQ=="

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      delete_on_termination = "true"
      iops                  = 3000
      throughput            = 250
      volume_size           = 150
      volume_type           = "gp3"
    }
  }

  metadata_options {
    http_put_response_hop_limit = 2
    http_tokens                 = "optional"
  }

  network_interfaces {
    device_index       = 0
    ipv4_address_count = 0
    ipv4_addresses     = []
    ipv4_prefix_count  = 0
    ipv4_prefixes      = []
    ipv6_address_count = 0
    ipv6_addresses     = []
    ipv6_prefix_count  = 0
    ipv6_prefixes      = []
    network_card_index = 0
    security_groups = [
      "sg-0d3d0f70f95dc133f"
    ]
  }

  tags = {
    "eks:cluster-name"                                       = "airflow-prod"
    "eks:nodegroup-name"                                     = "standard"
    "k8s.io/cluster-autoscaler/node-template/label/standard" = "true"
    "k8s.io/cluster-autoscaler/node-template/taint/standard" = "true:NoSchedule"
  }
}

resource "aws_launch_template" "prod_high_memory" {
  name          = "prod_high_memory"
  image_id      = "ami-03857889452e262ff"
  instance_type = "r6i.8xlarge"

  disable_api_stop        = false
  disable_api_termination = false

  security_group_names = []

  user_data = "TUlNRS1WZXJzaW9uOiAxLjAKQ29udGVudC1UeXBlOiBtdWx0aXBhcnQvbWl4ZWQ7IGJvdW5kYXJ5PSIvLyIKCi0tLy8KQ29udGVudC1UeXBlOiB0ZXh0L3gtc2hlbGxzY3JpcHQ7IGNoYXJzZXQ9InVzLWFzY2lpIgojIS9iaW4vYmFzaApzZXQgLWV4CkI2NF9DTFVTVEVSX0NBPUxTMHRMUzFDUlVkSlRpQkRSVkpVU1VaSlEwRlVSUzB0TFMwdENrMUpTVU0xZWtORFFXTXJaMEYzU1VKQlowbENRVVJCVGtKbmEzRm9hMmxIT1hjd1FrRlJjMFpCUkVGV1RWSk5kMFZSV1VSV1VWRkVSWGR3Y21SWFNtd0tZMjAxYkdSSFZucE5RalJZUkZSSmVVMUVUWGxOVkVVelRYcEJlVTVXYjFoRVZFMTVUVVJOZUU5RVJUTk5la0Y1VGxadmQwWlVSVlJOUWtWSFFURlZSUXBCZUUxTFlUTldhVnBZU25WYVdGSnNZM3BEUTBGVFNYZEVVVmxLUzI5YVNXaDJZMDVCVVVWQ1FsRkJSR2RuUlZCQlJFTkRRVkZ2UTJkblJVSkJTMVJVQ21acGRFUnJkRFUxY0RkYWFrcFBWMFo1YVRsdk0ySmpWV1pUTURGTWRWZG9hbUpYU1dabVlWQlRjR1JDVldkRmNVeFVjMk5TWjNveFZUVTFhRzF1Y25vS09ERldiblZtU2pnMk5UWnZSbTQ1WlhsMlVIUlFibFp2VTJkNk9EQmhjVTQ1VkZkaVJYTnVXR1ZDYVRsaFVXUlBiRmRoUTI1dEsyWk1kMEZGU21KbEt3bzBOM1UzV1cxSVRqbElUbE5hWVVSdFFTOVhkRmhTYzNNNU9GVmFWVXhhZGk5WlRuZ3phWGhuSzBOV1NXTlNheTl0VUZWVlZEVTJjbXhZSzI1S1NEUTBDbVF2ZUd4UFRXaE9iR3RCZFZWb2JtSnFOR016U1hoRmQxcDNlWGRYZVZOcGFXVk9ia1UyVFZsT2VrWnpiaTh3TVU5eVUwSjNSRzlWV0doaWVsaEpaR2tLVm5kR1VGaGFLMDg0VDNobFMzVkdNbnBzVFZsQ1UwUkVTV2hQTm0xMlowZHJTRGhXYWxWVlpUWXJhWGxOVFdWaE1GQm5MMGxYTVhWR2R6QjFiSHBVTndwR1dTdHpaRFEzV2s1M01UZE9jalZUU1dWelEwRjNSVUZCWVU1RFRVVkJkMFJuV1VSV1VqQlFRVkZJTDBKQlVVUkJaMHRyVFVFNFIwRXhWV1JGZDBWQ0NpOTNVVVpOUVUxQ1FXWTRkMGhSV1VSV1VqQlBRa0paUlVaTldYTmxjR0ZEZWtWcWEyMVFVbmRXTTNoVE5sbGlORWt6Y3poTlFUQkhRMU54UjFOSllqTUtSRkZGUWtOM1ZVRkJORWxDUVZGQmFqUmxZaTgzU1VNeFVsTlJXa05xZW5CaE5uSkZTV2hVWWxwc01YRTROaXR6TDB0blIwRkliWFlyWlZaQ2FtYzBSZ293WldKSFVFVnpaM05SVERscFNtZG5OMUkxTHpVdk4ydFZibVpEVlZwRlNWcExRMlJhY0ZSMGFrZHVWelJ1Y1hGSVVIY3lhRVUxY3pkRVFVcFNSSEpaQ25BMlVrVTJOemxTT1VWTVZUTm9TbVUxYjB0Uk9XUjFibXR0TWpsUWJWZHBhRzE1V1dzMmFraFlNMDEwVmpndlZqRmtSM0pQZVU0NGEyRkhjMXBKWTBZS1pHOHphMjgwVTJkR1VrOVdkMWR4YVRkTVFraHNWbE16VFRBMU5tdDBjbEpuWTNSMFRtUXZVRkE1VWpSU2IyY3JWalZvWlVOU2NtczFNMjVIZG1GQmR3b3lSRXQyVkhvNVZubHBlakJyWTB0TWFYcHZaREJyYjFwbkwwazFlSFYwWjNsbmRYQk1Za1pTZDFOT056WXhTbXhHU2xvcmFEaEhOVE4zY21OQ1IzcFFDamRyYkZVMVdqSnFVVk5sVTBGUGEwRXZUM3BUYzB4VWFWRTBNRXR4UzJSMVdYQXlUUW90TFMwdExVVk9SQ0JEUlZKVVNVWkpRMEZVUlMwdExTMHRDZz09CkFQSV9TRVJWRVJfVVJMPWh0dHBzOi8vRkMzRjdBODg1MDg2NzZBMzBEQ0FGRTdCMjYxOUI1NDQuZ3I3LmV1LXdlc3QtMS5la3MuYW1hem9uYXdzLmNvbQpLOFNfQ0xVU1RFUl9ETlNfSVA9MTcyLjIwLjAuMTAKL2V0Yy9la3MvYm9vdHN0cmFwLnNoIGFpcmZsb3ctcHJvZCAtLWt1YmVsZXQtZXh0cmEtYXJncyAnLS1ub2RlLWxhYmVscz1la3MuYW1hem9uYXdzLmNvbS9ub2RlZ3JvdXAtaW1hZ2U9YW1pLTAzODU3ODg5NDUyZTI2MmZmLGVrcy5hbWF6b25hd3MuY29tL2NhcGFjaXR5VHlwZT1PTl9ERU1BTkQsaGlnaC1tZW1vcnk9dHJ1ZSxla3MuYW1hem9uYXdzLmNvbS9ub2RlZ3JvdXA9aGlnaC1tZW1vcnkgLS1yZWdpc3Rlci13aXRoLXRhaW50cz1oaWdoLW1lbW9yeT10cnVlOk5vU2NoZWR1bGUgLS1tYXgtcG9kcz0yMzQnIC0tYjY0LWNsdXN0ZXItY2EgJEI2NF9DTFVTVEVSX0NBIC0tYXBpc2VydmVyLWVuZHBvaW50ICRBUElfU0VSVkVSX1VSTCAtLWRucy1jbHVzdGVyLWlwICRLOFNfQ0xVU1RFUl9ETlNfSVAgLS11c2UtbWF4LXBvZHMgZmFsc2UKCi0tLy8tLQ=="

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      delete_on_termination = "true"
      iops                  = 3000
      throughput            = 250
      volume_size           = 200
      volume_type           = "gp3"
    }
  }

  metadata_options {
    http_put_response_hop_limit = 2
    http_tokens                 = "optional"
  }

  network_interfaces {
    device_index       = 0
    ipv4_address_count = 0
    ipv4_addresses     = []
    ipv4_prefix_count  = 0
    ipv4_prefixes      = []
    ipv6_address_count = 0
    ipv6_addresses     = []
    ipv6_prefix_count  = 0
    ipv6_prefixes      = []
    network_card_index = 0
    security_groups = [
      "sg-0d3d0f70f95dc133f"
    ]
  }

  tags = {
    "eks:cluster-name"                                          = "airflow-prod"
    "eks:nodegroup-name"                                        = "high-memory"
    "k8s.io/cluster-autoscaler/node-template/label/high-memory" = "true"
    "k8s.io/cluster-autoscaler/node-template/taint/high-memory" = "true:NoSchedule"
  }
}
