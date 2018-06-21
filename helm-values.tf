locals {
  elasticsearch_endpoint = "https://${element(concat(aws_elasticsearch_domain.es.*.endpoint, aws_elasticsearch_domain.public_es.*.endpoint), 0)}"

  template_filename = "${substr("${path.module}/templates/helm-values.tpl.yaml", length(path.cwd) + 1, -1)}"
  // +1 for removing the "/"
  local_filename = "${substr("${path.module}/helm-values.yaml", length(path.cwd) + 1, -1)}"
}

data "template_file" "helm_values" {
  count    = "${length(var.prometheus_labels) != 0 ? 1 : 0}"
  template = "${local.template_filename}"

  vars {
    elasticsearch_endpoint = "${local.elasticsearch_endpoint}"
    prometheus_labels      = "${indent(4, join("\n", data.template_file.prometheus_kv_mapping.*.rendered))}"
  }
}

data "template_file" "prometheus_kv_mapping" {
  count    = "${length(var.prometheus_labels)}"
  template = "$${key}: $${value}"

  vars {
    key   = "${element(keys(var.prometheus_labels), count.index)}"
    value = "${element(values(var.prometheus_labels), count.index)}"
  }
}

resource "local_file" "helm_values_file" {
  count    = "${length(var.prometheus_labels) != 0 ? 1 : 0}"
  content  = "${data.template_file.helm_values.rendered}"
  filename = "${local.local_filename}"
}
