FROM ubuntu:18.04

RUN apt-get update && apt-get install -y openssh-server openjdk-8-jdk wget sudo

RUN wget https://dlcdn.apache.org/hadoop/common/hadoop-3.4.0/hadoop-3.4.0.tar.gz && \
    tar -xzvf hadoop-3.4.0.tar.gz && \
    mv hadoop-3.4.0 /usr/local/hadoop && \
    rm hadoop-3.4.0.tar.gz

ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64 
ENV HADOOP_HOME=/usr/local/hadoop 
ENV PATH=$PATH:/usr/local/hadoop/bin:/usr/local/hadoop/sbin 

# ssh without key
RUN ssh-keygen -t rsa -f ~/.ssh/id_rsa -P '' && \
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

RUN mkdir -p ~/hdfs/namenode && \ 
    mkdir -p ~/hdfs/datanode && \
    mkdir $HADOOP_HOME/logs

ENV HDFS_NAMENODE_USER="root"
ENV HDFS_DATANODE_USER="root"
ENV HDFS_SECONDARYNAMENODE_USER="root"
ENV YARN_RESOURCEMANAGER_USER="root"
ENV YARN_NODEMANAGER_USER="root"
ENV HADOOP_CONF_DIR=/usr/local/hadoop/etc/hadoop
ENV HADOOP_MAPRED_HOME=/usr/local/hadoop
ENV HADOOP_COMMON_HOME=/usr/local/hadoop
ENV HADOOP_HDFS_HOME=/usr/local/hadoop 
ENV YARN_HOME=/usr/local/hadoop
ENV PATH=$PATH:/usr/local/hadoop/bin

COPY config/hadoop/* /tmp/

RUN mv /tmp/hadoop-env.sh $HADOOP_HOME/etc/hadoop/hadoop-env.sh && \
    mv /tmp/hdfs-site.xml $HADOOP_HOME/etc/hadoop/hdfs-site.xml && \ 
    mv /tmp/core-site.xml $HADOOP_HOME/etc/hadoop/core-site.xml && \
    mv /tmp/mapred-site.xml $HADOOP_HOME/etc/hadoop/mapred-site.xml && \
    mv /tmp/yarn-site.xml $HADOOP_HOME/etc/hadoop/yarn-site.xml && \
    mv /tmp/workers $HADOOP_HOME/etc/hadoop/workers
RUN chmod +x $HADOOP_HOME/sbin/*
# format namenode
RUN /usr/local/hadoop/bin/hdfs namenode -format

RUN wget https://dlcdn.apache.org/spark/spark-3.5.1/spark-3.5.1-bin-hadoop3.tgz && \
    tar -xzvf spark-3.5.1-bin-hadoop3.tgz && \
    mv spark-3.5.1-bin-hadoop3 /usr/local/spark && \
    rm spark-3.5.1-bin-hadoop3.tgz

ENV SPARK_HOME=/usr/local/spark
ENV YARN_CONF_DIR=$HADOOP_HOME/etc/hadoop   
ENV PATH=$PATH:$SPARK_HOME/bin
ENV PATH=$PATH:$SPARK_HOME/sbin
ENV LD_LIBRARY_PATH=$HADOOP_HOME/lib/native:$LD_LIBRARY_PATH
ENV HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
COPY config/spark/* /tmp/

RUN mv /tmp/slaves $SPARK_HOME/conf/slaves && \
    mv /tmp/spark-env.sh $SPARK_HOME/conf/spark-env.sh

RUN chmod +x $SPARK_HOME/sbin/*

EXPOSE 4040 7077 8080 8081 18080 34047 8088 10000

COPY config/run-cluster.sh /tmp

RUN mv /tmp/run-cluster.sh /usr/local/run-cluster.sh && \
    chmod +x /usr/local/run-cluster.sh

CMD [ "sh", "-c", "./usr/local/run-cluster.sh; bash"]