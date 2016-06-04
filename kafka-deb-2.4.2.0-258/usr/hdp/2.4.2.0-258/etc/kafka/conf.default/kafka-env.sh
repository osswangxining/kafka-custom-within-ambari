
#!/bin/bash

# Set KAFKA specific environment variables here.

# The java implementation to use.
export JAVA_HOME=/usr/java/jdk1.7.0_79
export PATH=$PATH:$JAVA_HOME/bin
export PID_DIR=/var/run/kafka
export LOG_DIR=/var/log/kafka
export KAFKA_KERBEROS_PARAMS=
# Add kafka sink to classpath and related depenencies
if [ -e "/usr/lib/ambari-metrics-kafka-sink/ambari-metrics-kafka-sink.jar" ]; then
  export CLASSPATH=$CLASSPATH:/usr/lib/ambari-metrics-kafka-sink/ambari-metrics-kafka-sink.jar
  export CLASSPATH=$CLASSPATH:/usr/lib/ambari-metrics-kafka-sink/lib/*
fi
if [ -f /etc/kafka/conf/kafka-ranger-env.sh ]; then
. /etc/kafka/conf/kafka-ranger-env.sh
fi