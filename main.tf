terraform {
  backend "gcs" {
    bucket          = "<ENTER-BUCKET-NAME-HERE>" prefix          = "terraform/state"
  }
}

provider "google" {
  project           = "${var.project}"
}

module "airflow" {
  source            = "airflow/"
  project           = "${var.project}"
  xpn_project       = "${var.xpn_project}"
  network           = "${var.network}"
  service_account   = "${var.service_account}"
  client_ip_range   = "${var.client_ip_range}"
  disk_size_gb      = "${var.disk_size_gb}"
  disk_type         = "${var.disk_type}"
  client_ip_range   = "${var.client_ip_range}"
  instance_type     = "${var.instance_type}"
  instance_count    = "${var.instance_count}"
  xpn_project       = "${var.xpn_project}"
  tags              = "${var.tags}"
  zone              = "${var.zone}"
  subnetwork        = "${var.subnetwork}"
  maria_ip1         = "${var.maria_ip1}"
  maria_ip2         = "${var.maria_ip2}"
  airflow_user_mariadb_pwd =  "${var.airflow_user_mariadb_pwd}"
}
