#!/bin/bash
# The following script install and configures HA Airflow on each of 
# the instances created within the Terraform script

# Set up Python 2.7 virtualenv
apt-get -y update
apt-get install -y python-pip
pip install virtualenv
cd /root
virtualenv --python=/usr/bin/python2.7 controller2.7
source controller2.7/bin/activate

# Install Airflow dependencies
apt-get install -y libmariadbclient-dev
apt-get install -y mysql-client
SLUGIFY_USES_TEXT_UNIDECODE=yes pip install apache-airflow[gcp_api,async,celery,crypto,jdbc,hdfs,hive,ldap,mysql,rabbitmq,vertica]

# Set Airflow home directory
sleep 10s
export AIRFLOW_HOME=/root/airflow 
mkdir $AIRFLOW_HOME 
chmod 777 $AIRFLOW_HOME 
#cd $AIRFLOW_HOME


# Download and config proxySQl
cd /root/
wget https://github.com/sysown/proxysql/releases/download/v2.0.1/proxysql_2.0.1-ubuntu16_amd64.deb
dpkg -i proxysql_2.0.1-ubuntu16_amd64.deb

cat <<EOF > /etc/mysql/my.cnf
[client-server]

# Import all .cnf files from configuration directory
!includedir /etc/mysql/conf.d/
!includedir /etc/mysql/mariadb.conf.d/
[mysqld]
bind-address=0.0.0.0
explicit_defaults_for_timestamp = 1

EOF

service proxysql start
sleep 5s
echo 'entering mysql command'
mysql -uadmin -padmin -h 127.0.0.1 -P6032 -Bse "INSERT INTO mysql_galera_hostgroups (offline_hostgroup, writer_hostgroup,reader_hostgroup,backup_writer_hostgroup,active,max_writers,writer_is_also_reader,max_transactions_behind) VALUES (1,2,3,4,1,1,1,100);
INSERT INTO mysql_servers(hostgroup_id,hostname,port,weight) VALUES (2,'${maria_ip1}',3306,100);
INSERT INTO mysql_servers(hostgroup_id,hostname,port,weight) VALUES (3,'${maria_ip2}',3306,100);
UPDATE global_variables SET variable_value='2000' WHERE variable_name IN ('mysql-monitor_connect_interval','mysql-monitor_ping_interval','mysql-monitor_read_only_interval');
UPDATE global_variables SET variable_value='airflow' WHERE variable_name IN ('mysql-monitor_username');
UPDATE global_variables SET variable_value='${airflow_user_mariadb_pwd}' WHERE variable_name IN ('mysql-monitor_password');
INSERT INTO mysql_users(username, password, default_hostgroup) VALUES ('airflow', '${airflow_user_mariadb_pwd}', 2);
LOAD MYSQL VARIABLES TO RUNTIME;
SAVE MYSQL VARIABLES TO DISK;
LOAD MYSQL SERVERS TO RUNTIME;
SAVE MYSQL SERVERS TO DISK;
LOAD MYSQL USERS TO RUNTIME;
SAVE MYSQL USERS TO DISK;"
echo 'exiting mysql command'

# Initalize Airflow
airflow initdb
cd $AIRFLOW_HOME
rm airflow.db

sed -i -e '/executor =/ s/= .*/= LocalExecutor/' airflow.cfg
sed -i -e '/broker_url =/ s/= .*/= sqla+mysql:\/\/airflow:airflow@localhost:3306\/airflow/' airflow.cfg
sed -i -e '/sql_alchemy_conn =/ s/= .*/= mysql:\/\/airflow:${airflow_user_mariadb_pwd}@127.0.0.1:6033\/airflow/' airflow.cfg
sed -i -e '/result_backend =/ s/= .*/= db+mysql:\/airflow:${airflow_user_mariadb_pwd}@127.0.0.1:6033\/airflow/' airflow.cfg
sed -i -e '/dags_are_paused_at_creation =/ s/= .*/= True/' airflow.cfg

# Initialize Airflow
cd $AIRFLOW_HOME
airflow initdb
sleep 10s

# The following script installs the Airflow Failover Scheduler Controller
# program on the Airflow instances after Airflow has been configured. 


# Install Airflow Failover Scheduler Controller
apt-get -y install git
cd /root/airflow  #directory for airflow user
git clone https://github.com/teamclairvoyant/airflow-scheduler-failover-controller
pip install -e /root/airflow/airflow-scheduler-failover-controller/
echo 'sleep for 10 s'
sleep 10s
cd /root/airflow
sleep 5s

# Update airflow.cfg file to include the scheduler nodes in the cluster
scheduler_failover_controller init
sed -i -e '/scheduler_nodes_in_cluster =/ s/= .*/= ${airflow1_host},${airflow2_host}/' airflow.cfg

#scheduler_failover_controller test_connection

# Start Airflow with AFSC
sleep 10s
echo 'stdout: Starting failover controller'
scheduler_failover_controller start
#airflow webserver -p 8080
