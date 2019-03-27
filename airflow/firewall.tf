resource "google_compute_firewall" "airflow-airflow" {
  name    = "airflow-airflow-ssh-icmp-tf"  #allow airflow instances to ping each other
  network = "${var.network}"
  allow {
    protocol = "icmp"
  }
  allow {
    protocol = "tcp"
    ports    = ["22", "3306", "6032", "6033", "8080"]
  }
  source_tags = "${var.tags}"
  target_tags = "${var.tags}"
}

resource "google_compute_firewall" "bastion" {
  name    = "airflow-port8080-ssh-tf"
  network = "${var.network}"
  allow {
    protocol = "tcp"
    ports    = ["8080", "22"]
  }
  source_tags = "${var.tags}"
  target_tags = ["bastion"]
}



