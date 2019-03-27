# Airflow High Availability Terraform Template

This terraform template creates a High Availability Apache Airflow cluster by deploying 2 Apache Airflow instances managed by a Failover Scheduler Controller.

ProxySQL is configured on each instance to connect with a Multi-Master MariaDB Galera cluster.


## Pre-requisites

This template assumes that you already have a running MariaDB cluster.

[Terraform template to deploy MariaDB](https://github.com/jasonmar/terraform-mariadb-multiregion)


## Deployment with Terraform


1. Clone git repository

```sh
git clone https://github.com/jasonmar/terraform-airflow-ha
```


2. Change working directory to location of terraform templates

```sh
cd terraform-airflow-ha
```


3. Edit `terraform.tfvars` and set the desired number of Airflow instances, GCP zones and VPC network and subnet for each instance.

```
//name of the project to create resources in
project            = "myproject"

//name of the network
network            = "mynetwork"

//name of the service account to be created
service_account    = "myserviceaccount@myproject.iam.gserviceaccount.com"

//values for disk type and disk size for the disk to be attached with Airflow VMs. Can be changed as required.
disk_size_gb       = 100
disk_type          = "pd-standard"

//CIDR range for internal client IP
client_ip_range    = "10.0.0.0/8"

//Machine type of VM. Can be changed as required.
instance_type      = "n1-standard-2"

//total number of Airflow instances to be created
instance_count     = 2

//name of the project
xpn_project        = "myproject"

//change the zones in which Airflow instances are to be created if required
zone = {
  "0" = "us-east1-b"
  "1" = "us-central1-a"
}

//name of the subnetworks to create Airflow instances in
subnetwork = {
  "0" = "mysubnet"
  "1" = "mysubnet"
}

//internal IP of MariaDB server #1
maria_ip1 = "10.x.x.x"

//internal IP of MariaDB server #2
maria_ip2 = "10.x.x.x"

//Password for Airflow user on MariaDB server inside double quotes
airflow_user_mariadb_pwd = "changeit"
```


4. Specify your GCS bucket in `main.tf`

```
terraform {
	backend "gcs" {
		bucket = "<ENTER-BUCKET-NAME-HERE>"
		prefix = "terraform/state"
	}
}
```


5. When ready deploy the terraform modules. Enter yes on the prompt.
```sh
terraform plan
terraform apply
```


6. Ensure these resources are created successfully:
	* Firewall rules with open ssh, icmp and tcp ports 6033, 6032, 22, 8080, 3306
	* 2 VMs for Airflow instances
	* Service account with given name


7. SSH into the Airflow VMs created. The Airflow, python virtualenv and ProxySQL configurations are done during boot-up using startup scripts. The logs for these services can be checked at `/var/logs/daemon.log`


8. In order to manually run a command on Airflow instances, remember to activate python virtual environment first.
```bash
source /root/controller<version>/bin/activate
```


9. Check if the scheduler failover controller has started successfully. This can be done by tailing the log file mentioned above. If it mentions that scheduler is not able to start on the active node, run below command from `/root/airflow/` directory and type yes on the prompt. When scheduler failover controller starts, it tries to connect with the other Airflow server and if proper ssh key fingerprint is not present, it will stop at a prompt. At startup time, this will fail to start the scheduler but after typing yes on the prompt during manual execution it works.

```sh
scheduler_failover_controller start
```


10. To destroy all the resources created using terraform, use terraform destroy command from the top of the same terraform repo. Enter `yes` on the prompt.
```sh
terraform destroy
```


## Disclaimer

This is not an official Google project.


