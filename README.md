# Customize or extend kafka deployment and management within Apache Ambari
Customize or extend kafka deployment and management within Apache Ambari, including the version change different with the service provided by the specfic HDP stacks


If you want to customize or extend Kafka within Apache Ambari and HDP package, you should firstly deep dive into the common services provided by HDP package, including 
such scripts written by Python, XML configurations,etc.

The following steps provide the guide on how to upgrade Kafka from pre-built 0.8 or 0.9 (within HDP 2.x) to 0.10 which just was released recently together with new features.

Fortunately, you don't need to change any the scripts used for configure and deploy Kafka old version in this scenario.

##1. 定制Stack下的KAFKA service的配置描述文件metainfo.xml

/var/lib/ambari-server/resources/stacks/HDP/2.4/services/KAFKA
这儿的package name就是deb文件中的package name，需要匹配一致,内容如下：
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

<pre class="brush: xml; gutter: true;">
    &lt;metainfo>
      &lt;schemaVersion>2.0&lt;/schemaVersion>
      &lt;services>
        &lt;service>
          &lt;name>KAFKA&lt;/name>
          &lt;version>0.10.0.0&lt;/version>
          &lt;osSpecifics>
            &lt;osSpecific>
              &lt;osFamily>ubuntu14&lt;/osFamily>
              &lt;packages>
                &lt;package>
                  &lt;name> kafka-0-10-0-0-2420258&lt;/name>
                &lt;/package>
              &lt;/packages>
            &lt;/osSpecific>
          &lt;/osSpecifics>
        &lt;/service>
      &lt;/services>
    &lt;/metainfo>
</pre>

明白了这个，你就可以制作deb package了.

另外，注意的是kafka/bin目录下的kafka文件：
<pre>
Home dir
KAFKA_HOME=/usr/hdp/2.4.2.0-258/kafka
</pre>

##2. 制作定制化的Kafka deb package

dpkg-deb -b ./ ../kafka-0-10-0-0-2420258_ambari_ubuntu14.deb。

当然，遵循HDP KAFKA的定制目录结构是非常有必要的。目录 kafka-deb-2.4.2.0-258 是针对HDP 2.4.2.0-258版本下升级Kafka到0.10.0.0做的DEB package。

##3. 搭建Local Repository并更新生成描述信息

Naturally, one local Deb package repository should be ready to locate and install this new kafka 0.10.0.0 package. For example, use Nginx to setup the web server, and then create the description info by following the steps:

安装dpkg-dev，并执行dpkg-scanpackages 扫描依赖包并生成依赖关系gz包：
<pre>
root# apt-get install  dpkg-dev -y 
Reading package lists... Done
Building dependency tree
Reading state information... Done
dpkg-dev is already the newest version.
0 upgraded, 0 newly installed, 0 to remove and 0 not upgraded. 
root# cd /data/ 
/data# ls
soft
root# dpkg-scanpackages soft/ |gzip > soft/Packages.gz 
</pre>


关于HDP和HDP UTILS，也需要一起放到本local repository中，直接解压下载的tar ball即可。

/HDP/ubuntu14/2.x/updates/2.4.2.0/

/HDP-UTILS-1.1.0.20/repos/ubuntu14/


##4. Agent端的配置

###4.0 手工安装agent

amber-agent/cache是amber自带的common service、脚本等；
最好是手工安装agent，

wget -nv http://public-repo-1.hortonworks.com/ambari/ubuntu14/2.x/updates/2.2.2.0/ambari.list -O /etc/apt/sources.list.d/ambari.list

apt-key adv --recv-keys --keyserver keyserver.ubuntu.com B9733A7A07513CAD

apt-get update

- Install the Ambari Agent on every host in your cluster.
<pre>
apt-get install ambari-agent
</pre>
- Configure the Ambari Agent by editing the ambari-agent.ini file as shown in the following example:

- vi /etc/ambari-agent/conf/ambari-agent.ini
<pre>
[server]
hostname=<your.ambari.server.hostname>
url_port=8440
secured_url_port=8441
</pre>

- Start the agent on every host in your cluster.
<pre>
ambari-agent start
</pre>
The agent registers with the Server on start.


###4.1 Agent的安装源配置

首先确保每个agent的sources.list中，把local的kafka 0.10.0.0 repository加进去，并执行apt-get update;

`root@ambari3:/etc/apt# cat /etc/apt/sources.list `

`deb http://ambari1.local.respository soft/ `


###4.2 Agent的Kafka服务描述

修改每个agent机器的 /var/lib/ambari-agent/cache/stacks/HDP/2.4/services/KAFKA/metainfo.xml

可以直接从Ambari Server上远程copy过来： 
<pre>
scp metainfo.xml root@ambari3.agent:/var/lib/ambari-agent/cache/stacks/HDP/2.4/services/KAFKA
</pre>
同时，确保每个agent机器的/var/lib/ambari-agent/cache/stacks/HDP/2.4/services/KAFKA的packages目录不存在。


##5. 其他

- 1.如果需要清除deb package的缓存，或者手工更新deb文件， 请直接操作默认的缓存目录 /var/cache/apt/archives/

- 2.Agent上的脚本python:
<pre>
  /var/lib/ambari-agent/cache/common-services/KAFKA/0.8.1.2.2/package/scripts
</pre>

##6. Trouble Shooting

#### 1.Amabri安装
可以手工设置下javahome，离线加载java：

ambari-server setup -j /usr/java/jdk1.8.0_05/  
<pre>
Enter choice (1): 1
Database name (ambari):
Postgres schema (ambari):
Username (ambari):

Enter Database Password (bigdata):

web: admin/admin

About to start PostgreSQL
Organizing resource files at /var/lib/ambari-server/resources...
Server PID at: /var/run/ambari-server/ambari-server.pid
Server out at: /var/log/ambari-server/ambari-server.out

Server log at: /var/log/ambari-server/ambari-server.log
</pre>

####2.VPN下不能加载Ambari UI
The security policy of your company may require you to access the internal network via VPN (virtual private network). Some VPN clients have strict policy on what can be transferred via port 8080. If you try to load the Ambari web UI that runs on the default port 8080 via such a VPN client, you may see a blank web page with one line of text saying …Loading….

Change Ambari web UI Port

You can customize the port that Ambari web UI runs on to avoid hitting the VPN issue in the first place by following the steps listed below.

- On the Ambari Server node, as the user used to install Ambari, open /etc/ambari-server/conf/ambari.properties via a text editor. Look for property client.api.port

    - If the property exists and its value is 8080, change it to a different port that’s not being used by any other Linux processes. For example, if ambari.properties contains client.api.port=8080, and port 8088 is a free port on your Ambari Server node. Update the property to be client.api.port=8088
    - If the property does not exist, add the property to ambari.properties and set a port value that’s not being used by any other Linux processes. For example, if port 8088 is a free port on your Ambari Server node, add client.api.port=8088 to ambari.properties

- Restart Ambari Server
- Open the Ambari web UI on your web browser against the new port. You should now see the familiar log in page.For example, if you changed the port from 8080 to 8088, you should now use URL http://myserver.example.com:8088

####3.Using+APIs+to+delete+a+service+or+all+host+components+on+a+host
Note: These API calls do not uninstall the packages associated with the service and neither they remove the config or temp folders associated with the service components.

Before the PUT or DELETE calls, you can do a GET to ensure that the API is referring to a valid resource.

##### 1.Note all the host components associated with the service.
<pre>
curl -u admin:admin -H "X-Requested-By: ambari" -X GET  http://AMBARI_SERVER_HOST:8080/api/v1/clusters/c1/services/SERVICENAME
</pre>

##### 2.Ensure the service is stopped (you can use the Ambari Web-UI to stop the service as well)

Stop the whole service (ensure correct values are provided for AMBARI_SERVER_HOST, SERVICE_NAME):
<pre>
curl -u admin:admin -H "X-Requested-By: ambari" -X PUT -d '{"RequestInfo":{"context":"Stop Service"},"Body":{"ServiceInfo":{"state":"INSTALLED"}}}' http://AMBARI_SERVER_HOST:8080/api/v1/clusters/c1/services/SERVICE_NAME
</pre>

Stop individual components (ensure correct values are provided for AMBARI_SERVER_HOST, HOSTNAME, COMPONENT_NAME):

<pre>
curl -u admin:admin -H "X-Requested-By: ambari" -X PUT -d '{"RequestInfo":{"context":"Stop Component"},"Body":{"HostRoles":{"state":"INSTALLED"}}}' http://AMBARI_SERVER_HOST:8080/api/v1/clusters/c1/hosts/HOSTNAME/host_components/COMPONENT_NAME
</pre>

Stop all component instances (ensure correct values are provided for AMBARI_SERVER_HOST, SERVICE_NAME, COMPONENT_NAME) - just another way to stop Service members:
<pre>
curl -u admin:admin -H "X-Requested-By: ambari" -X PUT -d '{"RequestInfo":{"context":"Stop All Components"},"Body":{"ServiceComponentInfo":{"state":"INSTALLED"}}}' http://AMBARI_SERVER_HOST:8080/api/v1/clusters/c1/services/SERVICE_NAME/components/COMPONENT_NAME
</pre>

#####3.Delete the whole SERVICE
<pre>
curl -u admin:admin -H "X-Requested-By: ambari" -X DELETE  http://AMBARI_SERVER_HOST:8080/api/v1/clusters/c1/services/SERVICENAME
</pre>

#####4.Ubuntu NTP disable
<pre>
root@# echo 'never' > /sys/kernel/mm/transparent_hugepage/enabled
root@# cat /sys/kernel/mm/transparent_hugepage/enabled
always madvise [never]
root@# echo 'never' > /sys/kernel/mm/transparent_hugepage/defrag
root@# cat /sys/kernel/mm/transparent_hugepage/defrag
always madvise [never]
</pre>