#!/bin/sh

# Configuration
HADOOP_HOME="/opt/hadoop-3.3.6"
AWS_JAR="aws-java-sdk-bundle-1.12.367.jar"
HADOOP_AWS_JAR="hadoop-aws-3.3.6.jar"
JAVA_HOME="/usr/local/openjdk-11"
MAX_TRIES=8
SLEEP_BETWEEN_TRY=4

# Initialize Environment Variables
export HADOOP_HOME
export HADOOP_CLASSPATH="${HADOOP_HOME}/share/hadoop/tools/lib/${AWS_JAR}:${HADOOP_HOME}/share/hadoop/tools/lib/${HADOOP_AWS_JAR}"
export JAVA_HOME

# Function to check mariadb readiness
check_mariadb() {
  CURRENT_TRY=1
  until [ "$(telnet mariadb 3306 | sed -n 2p)" = "Connected to mariadb." ] || [ "$CURRENT_TRY" -gt "$MAX_TRIES" ]; do
    echo "Waiting for mariadb server..."
    sleep "$SLEEP_BETWEEN_TRY"
    CURRENT_TRY=$((CURRENT_TRY + 1))
  done

  if [ "$CURRENT_TRY" -gt "$MAX_TRIES" ]; then
    echo "ERROR: Timeout when waiting for mariadb."
    exit 1
  fi
}

# Function to check and initialize schema
check_schema() {
  /opt/apache-hive-metastore-3.0.0-bin/bin/schematool -dbType mysql -info
  if [ $? -eq 1 ]; then
    echo "Getting schema info failed. Probably not initialized. Initializing..."
    /opt/apache-hive-metastore-3.0.0-bin/bin/schematool -initSchema -dbType mysql
  fi
}

# Main Execution
check_mariadb
check_schema

# Start metastore
/opt/apache-hive-metastore-3.0.0-bin/bin/start-metastore
