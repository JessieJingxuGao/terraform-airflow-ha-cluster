resource "google_compute_instance" "airflow" {
  count        = "${var.instance_count}"
  project      = "${var.project}" 
  name         = "${format("airflow-tf-%03d", count.index)}"
  zone         = "${lookup(var.zone, count.index)}"
  machine_type = "${var.instance_type}"
  can_ip_forward       = false
  tags         = ["airflow"]
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
      type = "${var.disk_type}"
    }
  }
  network_interface {
    subnetwork   = "${lookup(var.subnetwork, count.index)}"
  }
  metadata = {
    startup-script = "${data.template_file.startup.rendered}"
  }
  ##metadata_startup_script = "echo hi > /test.txt"
  service_account {
    email = "airflow@retail-poc-demo.iam.gserviceaccount.com"
    scopes = ["cloud-platform"]
  }
}

data "template_file" "startup" {
  template = "${file("${path.module}/scripts/startup.sh.tpl")}"
  vars = {
    airflow1_host = "${format("airflow-tf-%03d", count.index)}" 
    airflow2_host = "${format("airflow-tf-%03d", count.index+1)}"
    maria_ip1 = "${var.maria_ip1}"
    maria_ip2 = "${var.maria_ip2}"
    airflow_user_mariadb_pwd = "${var.airflow_user_mariadb_pwd}"
  }
}
