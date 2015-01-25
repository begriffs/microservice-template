### Microservice Template ([see video](foo))

The scalable monitored template for cluster infrastructure.

* Provision servers with Packer and Chef
* Deploy and scale with Terraform
* Service discovery with Consul
* Data collection with collectd and statsd
* Analysis and visualization with InfluxDB and Grafana

#### Installation

1. Create Amazon IAM credentials for deployment.**
    Assuming you are signed into the AWS console, visit the [user
    admin](https://console.aws.amazon.com/iam/home#users) page. Create
    a new user and note their security credentials (ID and secret key).
    Then attach a user policy of "Power User" to the newly created user.

2. Clone this repo including its chef recipe submodules.
    ```bash
    git clone --recursive https://github.com/begriffs/microservice-template.git
    ```

3. Install [Packer](https://www.packer.io/) and [Terraform](https://www.terraform.io/)
4. Create machine images (AMI) using your credentials.
    When running each of these commands take note of the AMI ids each
    one generates. They will be of the form `ami-[hash]`.

    ```bash
    packer build -var 'aws_access_key=xxx' -var 'aws_secret_key=xxx' consul.json
    packer build -var 'aws_access_key=xxx' -var 'aws_secret_key=xxx' statsd.json
    packer build -var 'aws_access_key=xxx' -var 'aws_secret_key=xxx' influx.json
    packer build -var 'aws_access_key=xxx' -var 'aws_secret_key=xxx' grafana.json
    ```

5. Deploy machine images.
    Edit `terraform/vars.tf` and fill in the ami instances created by
    the previous steps. Then go into the terraform directory and run
    `make`.

    At the end it will output the public IP address of the monitoring
    server for the cluster. You can use it to watch server health and
    resource usage.

#### Monitoring

The server exposes web interfaces for several services.

Port | Service
---- | -------------------------------------
80   | [Grafana](http://grafana.org/) charts
8500 | Consul server status and key/vals
8080 | InfluxDB admin panel
8086 | InfluxDB API used by Grafana

Influx has been configured with two databases, `metrics` and
`grafana`. Cluster data accumulates in the former and Grafana stores
your chart settings in the latter. The Influx user `grafana` (password
`grafpass`) has full access to both tables.

#### Collecting more stats

The cluster exposes [StatsD](https://github.com/etsy/statsd/)
server(s) at `statsd.node.consul`. Your applications should send
it lots of events. The statsd protocol is UDP and incurs little
application delay. The statsd server relays all info to InfluxDB
which makes it accessible for graphing.
