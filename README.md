### Microservice Template ([see video](http://begriffs.com/posts/2015-02-15-microservice-template.html))

The scalable monitored template for cluster infrastructure.

* Provision servers with Packer and Chef
* Deploy and scale with Terraform
* Service discovery with Consul
* Data collection with collectd and statsd
* Analysis and visualization with InfluxDB and Grafana

#### Installation

1. Sign up for Amazon Web Services free tier [here](http://aws.amazon.com/free/).
    It is **extremely important** to ensure the region in your
    Amazon Web Console is set to "N. California" or future steps
    will fail mysteriously.

2. Create Amazon IAM credentials for deployment.
    Assuming you are signed into the AWS console, visit the [user
    admin](https://console.aws.amazon.com/iam/home#users) page. Create
    a new user and note their security credentials (ID and secret key).
    Then attach a user policy of "Power User" to the newly created user.

3. [Create EC2 keypair](https://console.aws.amazon.com/ec2/v2/home?region=us-west-1#KeyPairs:sort=keyName)
    named `terraform`.

4. Clone this repo including its chef recipe submodules.
    ```bash
    git clone --recursive https://github.com/begriffs/microservice-template.git

    # if you've already cloned the repo you can do: git submodule update --init
    ```

5. Install <a href="https://www.packer.io/" target="_blank">Packer</a> and
    <a href="https://www.terraform.io/" target="_blank">Terraform</a>. On a
    Mac you can install them with homebrew:
    ```bash
    brew tap homebrew/binary
    brew install packer
    brew install terraform
    ```

6. Create machine images (AMI) using your credentials.
    When running each of these commands **write down** the AMI ids
    each one generates. They will be of the form `ami-[hash]`. You
    will need to remember which command created which AMI.
    AWS credentials are required and can be provided on the command line or
    accessed from environment variables `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`.

    Optionally the region can be specified via command line. If specifying a region the proper
    source ami must also be provided via command line.

    ####Region to source ami mappings.
    ```bash
       us-east-1: ami-b66ed3de
       us-west-1: ami-4b6f650e
       us-west-2: ami-b5a7ea85
       eu-west-1: ami-607bd917
       ap-southeast-1: ami-ac5c7afe
       ap-southeast-2: ami-63f79559
       ap-northeast-1: ami-4985b048
       sa-east-1: ami-8737829a
    ```

    If no region is specified on the command line a default region of `us-west-1` is used
    with a source_ami of `ami-4b6f650e`.

    ```bash
    packer build -var 'aws_access_key=xxx' -var 'aws_secret_key=xxx' -var 'region=us-east-1' -var 'source_ami=ami-b66ed3de' consul.json 
    packer build -var 'aws_access_key=xxx' -var 'aws_secret_key=xxx' statsd.json
    packer build -var 'aws_access_key=xxx' -var 'aws_secret_key=xxx' influx.json
    packer build -var 'aws_access_key=xxx' -var 'aws_secret_key=xxx' grafana.json
    packer build -var 'aws_access_key=xxx' -var 'aws_secret_key=xxx' rabbitmq.json

    # for haskell workers
    packer build -var 'aws_access_key=xxx' -var 'aws_secret_key=xxx' halcyon.json
    ```

7. Deploy machine images.
    Edit `terraform/vars.tf` and fill in the ami instances created by
    the previous steps. Leave the `aws` keys blank.
    Copy the Terraform variables example to a file without the `.example`
    and fill it in. Optionally provide a region and availability zone. 
    All other information is required.  A default region of `us-west-1` 
    and availabilty zone of `us-west-1a` are used.
    ```bash
    cp terraform/terraform.tfvars{.example,}
    ```

    Now the fun part. Go into the terraform directory and run `make`.

    At the end it will output the public IP address of the monitoring
    server for the cluster. You can use it to watch server health and
    resource usage.

#### Monitoring

The server exposes web interfaces for several services.

Port  | Service
----- | -------------------------------------
80    | [Grafana](http://grafana.org/) charts
8500  | Consul server status and key/vals
8080  | InfluxDB admin panel
8086  | InfluxDB API used by Grafana
15672 | RabbitMQ management console

Influx has been configured with two databases, `metrics` and
`grafana`. Cluster data accumulates in the former and Grafana stores
your chart settings in the latter. The Influx user `grafana` (password
`grafpass`) has full access to both tables. RabbitMQ is set up with
user `guest` password `guest`.

#### Collecting more stats

The cluster exposes [StatsD](https://github.com/etsy/statsd/)
server(s) at `statsd.node.consul`. Your applications should send
it lots of events. The statsd protocol is UDP and incurs little
application delay. The statsd server relays all info to InfluxDB
which makes it accessible for graphing.
