# Kafka ZooKeeper Directories 
## Notation
When an element in a path is denoted [xyz], that means that the value of xyz is not fixed and there is in fact a ZooKeeper znode for each possible value of xyz. 

For example /topics/[topic] would be a directory named /topics containing a sub-directory for each topic name. 

Numerical ranges are also given such as [0...5] to indicate the subdirectories 0, 1, 2, 3, 4. An arrow -> is used to indicate the contents of a znode. 

For example /hello -> world would indicate a znode /hello containing the value "world".

## Broker Node Registry
<pre>/brokers/ids/[0...N] --> 
{"jmx_port":...,"timestamp":...,"endpoints":[...],"host":...,"version":...,"port":...} (ephemeral node)</pre>

This is a list of all present broker nodes, each of which provides a unique logical broker id which identifies it to consumers (which must be given as part of its configuration). On startup, a broker node registers itself by creating a znode with the logical broker id under /brokers/ids. The purpose of the logical broker id is to allow a broker to be moved to a different physical machine without affecting consumers. An attempt to register a broker id that is already in use (say because two servers are configured with the same broker id) results in an error.

## Broker Topic Registry

<pre>/brokers/topics/[topic]/partitions/[0...N]/state --> 
{"controller_epoch":...,"leader":...,"version":...,"leader_epoch":...,"isr":[...]} (ephemeral node)
</pre>
Each broker registers itself under the topics it maintains and stores the number of partitions for that topic.

## Consumers and Consumer Groups
Consumers of topics also register themselves in ZooKeeper, in order to coordinate with each other and balance the consumption of data. Consumers can also store their offsets in ZooKeeper by setting <pre>offsets.storage=zookeeper</pre> 
However, this offset storage mechanism will be deprecated in a future release. Therefore, it is recommended to migrate offsets storage to Kafka.

Multiple consumers can form a group and jointly consume a single topic. Each consumer in the same group is given a shared group_id. For example if one consumer is your foobar process, which is run across three machines, then you might assign this group of consumers the id "foobar". This group id is provided in the configuration of the consumer, and is your way to tell the consumer which group it belongs to.
The consumers in a group divide up the partitions as fairly as possible, each partition is consumed by exactly one consumer in a consumer group.

## Consumer Id Registry
In addition to the group_id which is shared by all consumers in a group, each consumer is given a transient, unique consumer_id (of the form hostname:uuid) for identification purposes. Consumer ids are registered in the following directory.
<pre>/consumers/[group_id]/ids/[consumer_id] --> 
{"version":...,"subscription":{...:...},"pattern":...,"timestamp":...} (ephemeral node)</pre>
Each of the consumers in the group registers under its group and creates a znode with its consumer_id. The value of the znode contains a map of &lt;topic, streams>. This id is simply used to identify each of the consumers which is currently active within a group. This is an ephemeral node so it will disappear if the consumer process dies.

### Consumer Offsets

Consumers track the maximum offset they have consumed in each partition. This value is stored in a ZooKeeper directory if offsets.storage=zookeeper.
<pre>/consumers/[group_id]/offsets/[topic]/[partition_id] --> offset_counter_value ((persistent node)</pre>

- ** The consumer offsets stored in Zookeeper will not migrated to the target Kafka.

- ** The consumer offsets stored in Kafka internal topic (__consumer_offsets) will also not migrated to the target Kafka.


### Partition Owner registry

Each broker partition is consumed by a single consumer within a given consumer group. The consumer must establish its ownership of a given partition before any consumption can begin. To establish its ownership, a consumer writes its own id in an ephemeral node under the particular broker partition it is claiming.
<pre>/consumers/[group_id]/owners/[topic]/[partition_id] --> consumer_node_id (ephemeral node)</pre>

### Broker node registration

The broker nodes are basically independent, so they only publish information about what they have. When a broker joins, it registers 
itself under the broker node registry directory and writes information about its host name and port. 

The broker also register the list of existing topics and their logical partitions in the broker topic registry. New topics are registered dynamically when they are created on the broker.


### Consumer registration algorithm
When a consumer starts, it does the following:

- 1.Register itself in the consumer id registry under its group.
- 2.Register a watch on changes (new consumers joining or any existing consumers leaving) under the consumer id registry. (Each change triggers rebalancing among all consumers within the group to which the changed consumer belongs.)
- 3.Register a watch on changes (new brokers joining or any existing brokers leaving) under the broker id registry. (Each change triggers rebalancing among all consumers in all consumer groups.)
- 4.If the consumer creates a message stream using a topic filter, it also registers a watch on changes (new topics being added) under the broker topic registry. (Each change will trigger re-evaluation of the available topics to determine which topics are allowed by the topic filter. A new allowed topic will trigger rebalancing among all consumers within the consumer group.)
- 5.Force itself to rebalance within in its consumer group.


##Consumer rebalancing algorithm
The consumer rebalancing algorithms allows all the consumers in a group to come into consensus on which consumer is consuming which partitions. Consumer rebalancing is triggered on each addition or removal of both broker nodes and other consumers within the same group. For a given topic and a given consumer group, broker partitions are divided evenly among consumers within the group. 

<b>A partition is always consumed by a single consumer.</b> This design simplifies the implementation. Had we allowed a partition to be concurrently consumed by multiple consumers, there would be contention on the partition and some kind of locking would be required. If there are more consumers than partitions, some consumers won't get any data at all. During rebalancing, we try to assign partitions to consumers in such a way that reduces the number of broker nodes each consumer has to connect to.

Each consumer does the following during rebalancing:

-   1.For each topic T that Ci subscribes to
-   2.let PT be all partitions producing topic T
-   3.let CG be all consumers in the same group as Ci that consume topic T
-   4.sort PT (so partitions on the same broker are clustered together)
-   5.sort CG
-   6.let i be the index position of Ci in CG and let N = size(PT)/size(CG)
-   7.assign partitions from i*N to (i+1)*N - 1 to consumer Ci
-   8.remove current entries owned by Ci from the partition owner registry
-   9.add newly assigned partitions to the partition owner registry

(we may need to re-try this until the original partition owner releases its ownership)
When rebalancing is triggered at one consumer, rebalancing should be triggered in other consumers within the same group about the same time.


## How to clean the topics which are marked for deletion?
- 1.Delete topic folder from Kafka broker machine.

<pre>root@ambari4:/kafka-logs# rm -rf TBDeletedTopic-* </pre>

- 2.Login to zookeeper and -

<pre>
root#zkcli
rmr /brokers/topics/{topic_name}
rmr /admin/delete_topics/{topic_name}
</pre>
