# Customize or extend kafka deployment and management within Apache Ambari
Customize or extend kafka deployment and management within Apache Ambari, including the version change different with the service provided by the specfic HDP stacks


If you want to customize or extend Kafka within Apache Ambari and HDP package, you should firstly deep dive into the common services provided by HDP package, including 
such scripts written by Python, XML configurations,etc.

The following steps provide the guide on how to upgrade Kafka from pre-built 0.8 or 0.9 (within HDP 2.x) to 0.10 which just was released recently together with new features.

Fortunately, you don't need to change any the scripts used for configure and deploy Kafka old version in this scenario.

1. 定制Stack下的KAFKA service的配置描述文件metainfo.xml

/var/lib/ambari-server/resources/stacks/HDP/2.4/services/KAFKA
这儿的package name就是deb文件中的package name，需要匹配一致。

<metainfo>
  <schemaVersion>2.0</schemaVersion>
  <services>
    <service>
      <name>KAFKA</name>
      <version>0.10.0.0</version>
      <osSpecifics>
        <osSpecific>
          <osFamily>ubuntu14</osFamily>
          <packages>
            <package>
              <name> kafka-0-10-0-0-2420258</name>
            </package>
          </packages>
        </osSpecific>
      </osSpecifics>
    </service>
  </services>
</metainfo>

明白了这个，你就可以制作deb package了, 

2. 制作定制化的Kafka deb package

dpkg-deb -b ./ ../kafka-0-10-0-0-2420258_ambari_ubuntu14.deb。

当然，遵循HDP KAFKA的定制目录结构是非常有必要的。目录 kafka-deb-2.4.2.0-258 是针对HDP 2.4.2.0-258版本下升级Kafka到0.10.0.0做的DEB package。

Naturally, one local Deb package repository should be ready to locate and install this new kafka 0.10.0.0 package. For example, use Nginx to setup the web server, and then create the description info by following the steps:

3. 搭建Local Repository并更新生成描述信息

安装dpkg-dev，并执行dpkg-scanpackages 扫描依赖包并生成依赖关系gz包：

# apt-get install  dpkg-dev -y
Reading package lists... Done
Building dependency tree
Reading state information... Done
dpkg-dev is already the newest version.
0 upgraded, 0 newly installed, 0 to remove and 0 not upgraded.
# cd /data/
/data# ls
soft
# dpkg-scanpackages soft/ |gzip > soft/Packages.gz

关于HDP和HDP UTILS，也需要一起放到本local repository中，直接解压下载的tar ball即可。
/HDP/ubuntu14/2.x/updates/2.4.2.0/
/HDP-UTILS-1.1.0.20/repos/ubuntu14/


4. Agent端的配置

4.0 手工安装agent

amber-agent/cache是amber自带的common service、脚本等；
最好是手工安装agent，

- Install the Ambari Agent on every host in your cluster.
apt-get install ambari-agent

- Configure the Ambari Agent by editing the ambari-agent.ini file as shown in the following example:

- vi /etc/ambari-agent/conf/ambari-agent.ini
[server]
hostname=<your.ambari.server.hostname>
url_port=8440
secured_url_port=8441

- Start the agent on every host in your cluster.
ambari-agent start
The agent registers with the Server on start.


4.1 Agent的安装源配置

首先确保每个agent的sources.list中，把local的kafka 0.10.0.0 repository加进去，并执行apt-get update;

root@ambari3:/etc/apt# cat /etc/apt/sources.list

deb http://ambari1.local.respository soft/


4.2 Agent的Kafka服务描述

修改每个agent机器的 /var/lib/ambari-agent/cache/stacks/HDP/2.4/services/KAFKA/metainfo.xml
可以直接从Ambari Server上远程copy过来： scp metainfo.xml root@ambari3.agent:/var/lib/ambari-agent/cache/stacks/HDP/2.4/services/KAFKA
同时，确保每个agent机器的/var/lib/ambari-agent/cache/stacks/HDP/2.4/services/KAFKA的packages目录不存在。


5. 其他

如果需要清除deb package的缓存，或者手工更新deb文件， 请直接操作默认的缓存目录 /var/cache/apt/archives/

