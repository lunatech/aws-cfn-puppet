Quick Start
===========

1. Install the Amazon CloudFormation CLI kit (<https://s3.amazonaws.com/cloudformation-cli/AWSCloudFormation-cli.zip>).

2. Create a EC2 key pair for remote access to your instances.

3. Generate the CFN templates from the Makefile:

        cd cloudformation
		make

3. Create the stack and monitor its progress with the commands:

        cfn-create-stack Demo -d --parameters "KeyName=<YOUR KEY NAME HERE>" --template-file aws-cfn-puppet.json --capabilities CAPABILITY_IAM
		cfn-describe-stack-events Demo
   
   Substitute your key name appropriately. The "-d" parameter will prevent
   CloudFormation from rolling back your stack something goes wrong. Be
   sure to shut it down manually with `cfn-delete-stack` if this 
   happens to avoid getting charged for uptime your resources.
	
4. Connect to your stack via SSH as the user "ubuntu" at the address
   contained in output `cc1PublicDNSName`; Connect to front-end servers
   via HTTP at address contained in output `elb1PublicDNSName`. For
   example, to connect to the `cc1` node issue a command like:
   
        ssh ubuntu@ec2-54-211-176-173.compute-1.amazonaws.com
   
   Or to access the web application:
   
        curl http://Demo-elb1-1BVWGP4PF017T-1442325718.us-east-1.elb.amazonaws.com/hello
   
   Note that these host names are only examples; You must obtain the actual
   values for these resources in your stack via the 
   `cfn-describe-stack-resources` command.


Overview
========

This project demonstrates the creating the infrastructure for a
moderately complicated web application using AWS CloudFormation and
Puppet with the following features:

* Load balanced web servers
* Back-end servers driven by message queues
* Shared storage file storage
* Centralized management of common services (e.g.logging)
* Python with Apache and mod_wsgi

I'm taking advantage of Amazon infrastructure services wherever
possible:

* S3 for file storage
* SQS for messaging between the front-end and back-end servers
* SDB domain for storing undeliverable messages (DLO)
* Autoscaling groups to manage server load
* Restricted access to machines with security groups
* ELB for load balancing

The general approach is to use CloudFormation to provision all AWS
resources, and to use Puppet to handle configuration of the software and
services on the EC2 instances. In the EC2-related pieces of the 
CloudFormation templates, we'll install just enough software onto the
base AMI to get Puppet up and running and let it handle all further
instance configuration.

The examples are based on Ubuntu 12.04, but the concepts should be
transferrable to other operating systems.


CloudFormation
==============

The template for this part of the app is based on the guide found at
<https://s3.amazonaws.com/cloudformation-examples/IntegratingAWSCloudFormationWithPuppet.pdf>
but extends it to create multiple instance "personalities" and the 
additional AWS resources described above. An overview of the template
features is provided below. Refer to the template itself for full
details.

The following parameters are supported:


|Parameter|Reqiured?|Description|Default|
|---------|---------|-----------|-------|
|`KeyName`|Yes|SSH key for access to EC2 instances|_None_|
|`CCInstanceType`|No|Instance type for CC nodes|t1.micro|
|`FEInstanceType`|No|Instance type for FE nodes|t1.micro|
|`BEInstanceType`|No|Instance type for BE nodes|t1.micro|
|`MinFEInstances`|No|Minimum number of nodes in FEAutoScalingGroup|1|
|`MaxFEInstances`|No|Maximum number of nodes in FEAutoScalingGroup|1|
|`MinBEInstances`|No|Minimum number of nodes in BEAutoScalingGroup|1|
|`MaxBEInstances`|No|Maximum number of nodes in BEAutoScalingGroup|1|
|`AppQueueVisibilityTimeout`|No|Default visibility timeout for messages in AppQueue|30|

In the `Mappings` section, the AMI IDs contained in `AWSRegionArch2AMI`
reference Ubuntu 12.04 images taken from <http://cloud-images.ubuntu.com/locator/ec2/>

The template creates two IAM users: `CFNInitUser` and `AppUser`.
`CFNInitUser` exists solely to execute the `cfn-init` command at instance
startup time and is only given permission to run the `DescribeStackResources`
command; `AppUser` is given full access to the S3 `AppBucket`, SQS
`AppQueue` and SDB `AppQueueDeadLetterOffice` resources and is created
to allow application code to utilize them.

The template creates an EC2 instance `cc1` that is intended to function
as a command-and-control node for the stack. It will function as a Puppet
master node, as well as a locus for various application services 
that are configured through Puppet (e.g. logging). `cc1` is also a Puppet
client.

Front-end and back-end instances are created with the launch configurations
assocaited with the `FEAutoScalingGroup` and `BEAutoScalingGroup`. These
instances will function as Puppet clients. The load balancer `elb1` will
pass HTTP traffic to the instances in the `FEAutoScalingGroup`.

Security groups are created as follows to permit traffic between the 
from the internet into the stack as follows:

|Service|To Nodes|
|-------|--------|
|SSH|`cc1`|
|HTTP|`elb1`|

Internally, the following communication paths are permitted:

|Service|From Nodes|To Nodes|
|-------|----------|--------|
|SSH|`cc1`|`FEAutoScalingGroup`, `BEAutoScalingGroup`|
|HTTP|`elb1`|`FEAutoScalingGroup`|
|Syslog|`FEAutoScalingGroup`, `BEAutoScalingGroup`|`cc1`|
|Puppet|`FEAutoScalingGroup`, `BEAutoScalingGroup`|`cc1`|

Lastly, the template produces the following outputs:

|Output|Description|
|------|-----------|
|cc1PublicDNSName|Public DNS name of `cc1` instance|
|elb1PublicDNSName|Public DNS name of the `elb1` load balancer|
|appBucketURL|URL endpoint for the S3 `AppBucket`|
|appQueueURL|URL endpoint for the SQS `AppQueue`|
|appQueueDeadLetterOfficeDomainName|Name of the SDB domain for storing undeliverable messages sent to `AppQueue`|


Stack Startup
=============

The Ubuntu AMIs in this example are outfitted with the `cloud-init`
package (<https://help.ubuntu.com/community/CloudInit>) that supports
the execution of `UserData` scripts at launch time. Each instance
runs a simple script (defined in the `Properties` section of its 
launch configuration in the template) that installs the 
`aws-cfn-bootstrap` software and `cfn-init` as the `CFNInitUser`.
   
The `cfn-init` program then installs just enough software and configuration
to start the Puppet client (and Puppet master on `cc1`). To ensure
proper synchronization of events, the template creates a  wait condition
(`PuppetMasterWaitCondition`) that blocks launch of the front- and
back-end nodes until `cc1` has succesfully started and the Puppet master
service is running.

At this point, all further configration of EC2 nodes is driven by
Puppet.


Puppet Configuration
====================

* Configure auto-signing of certificates in `/etc/puppet/autosign.conf`

* Install the `cfn-facter-plugin` for propagting variables from
  CloudFormation templates to Puppet manifests.

  All instances are given access to key aspects of the stack via the 
  via the `Puppet` metadata entry in their launch configurations and 
  may be accessed via the following variables:
  
  |Key|Description|
  |---|-----------|
  |app_user_access_key_id||
  |app_user_secret_access_key||
  |app_bucket_url|URL endpoint for the S3 `AppBucket`|
  |app_queue_url|URL endpoint for the SQS `AppQueue`|
  |app_queue_dead_letter_office_domain_name|Name of the SDB domain for storing undeliverable messages sent to `AppQueue`|

* Generate cert names for puppet clients that encode their personality
  (cc, fe, be) so we can match on them in `nodes.pp`. The default is
  to generate a certificate based on hostname, but this is problematic
  because hostnames are unpredictable, and in the case of auto-scaling 
  groups, the number/identity of nodes isn't known in advance or 
  obvious from the hostname. Also Puppet seems to have issues with
  uppercase characters in certificate names, which appear in instance
  hostnames.
	   
  So the approach is to figure out the AWS assigned hostname (via a call
  to `http://169.254.169.254/latest/meta-data/hostname`, force it to
  lowercase, and prepend a string that indicates the role to the front
  of this. Additionally, Ubuntu doesn't seem to start the puppet client
  by default, so we have to generate a `/etc/defaults/puppet` file that
  makes it work the way we want.
  
* Create a drop point at `/var/dist` so cc1 can distribute content to
  clients via `puppet:///dist/*` URLs
  
* On `cc1`, import modules and a site configuration into `/etc/puppet`
  from this GitHub repo. 


Puppet Modules
==============

Once the servers are started, Puppet takes over the configuration and
starts installing software on the front- and back-end hosts. The
file `site.pp` describes the configuration of nodes based on their role
(cc, fe or be).

Each machine will be outfitted with common services, including ntpd and
syslog. Syslog on all machines will be set to forward logs to `cc1`
over TCP. On `cc1` individual machine logs will be stored in
`/var/log/hosts` and select logs (for facilities local1, local2 and local3)
will be aggregaged into files under `/var/log/consolidated`.

Additionally, each machine will have Python installed and a virtualenv 
created at `/var/virtualenv`. The front-end machines will also
be outfitted with Apache 2 and mod_wsgi. A sample WSGI application is
available at `/hello` on the front-end machines that prints out a
the Python configuration. You should see that its source root is the
virtualenv created above.

Lastly, a configuration file will be generated at `/etc/hello.conf` for 
use by application components. This will contain the AWS credentials for
the `AppUser` configured for the stack and the endpoint URLs for the
S3 `AppBucket` and SQS `AppQueue`.


TODO
====

* Deploy application code into virtualenv
* RDS (or other) database instance
* ElastiCache layer

