# kafka-custom-within-ambari
Customize or extend kafka deployment and management within Apache Ambari, including the version change different with the service provided by the specfic HDP stacks


If you want to customize or extend Kafka within Apache Ambari and HDP package, you should firstly deep dive into the common services provided by HDP package, including 
such scripts written by Python, XML configurations,etc.

The following steps provide the guide on how to upgrade Kafka from pre-built 0.8 or 0.9 (within HDP 2.x) to 0.10 which just was released recently together with new features.

Fortunately, we don't need to change any the scripts used for configure and deploy Kafka old version in this scenario.

KAFKA 配置描述文件：metainfo.xml

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

明白了这个，你就可以制作deb package了。当然，遵循HDP KAFKA的定制目录结构是非常有必要的。 