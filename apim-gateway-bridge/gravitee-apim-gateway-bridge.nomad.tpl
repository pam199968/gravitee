job "gravitee-apim-gateway-bridge" {

    type = "service"

    datacenters = ["${datacenter}"]

    update {
        stagger = "30s"
        max_parallel = 1
    }

    vault {
        policies = ["gravitee"]
        change_mode = "restart"
    }
	
    group "apim-gateway-bridge" {
        count = 1
        network {
            mode = "host"
            port "bridge-port" { to = 18092 }
        }
        task "apim-gateway-bridge" {
            driver = "docker"

            config {
                image = "${image}:${tag}"
                ports = ["bridge-port"]
            }

            resources {
                cpu = 500
                memory = 1000
            }

            template {
                data = <<EOD
# mongodb
gravitee.ds.mongodb.host = {{ range service "gravitee-mongodb" }}{{.Address}}{{end}}
gravitee.ds.mongodb.port = {{ range service "gravitee-mongodb" }}{{.Port}}{{end}}
gravitee.management.mongodb.authSource = admin
gravitee.management.mongodb.username = {{ with secret "gravitee/mongodb" }}{{.Data.data.root_user}}{{end}}
gravitee.management.mongodb.password = {{ with secret "gravitee/mongodb" }}{{.Data.data.root_pass}}{{end}}
gravitee.ratelimit.mongodb.uri = mongodb://{{ with secret "gravitee/mongodb" }}{{.Data.data.root_user}}:{{.Data.data.root_pass}}{{end}}@{{ range service "gravitee-mongodb" }}{{.Address}}:{{.Port}}{{end}}/gravitee?authSource=admin
# elasticsearch
gravitee.ds.elastic.host = {{ range service "gravitee-elasticsearch" }}{{.Address}}{{end}}
gravitee.ds.elastic.port = {{ range service "gravitee-elasticsearch" }}{{.Port}}{{end}}
gravitee.reporters.elasticsearch.security.username={{ with secret "gravitee/elasticsearch" }}{{.Data.data.root_user}}{{end}}
gravitee.reporters.elasticsearch.security.password={{ with secret "gravitee/elasticsearch" }}{{.Data.data.root_pass}}{{end}}
# api properties encryption secret override
gravitee_api_properties_encryption_secret={{ with secret "gravitee/apim" }}{{.Data.data.encryption_secret}}{{end}}
_JAVA_OPTIONS="${user_java_opts}"
# Le heartbeat est en doublon avec Nomad et se marie mal avec l'allocation dynamique
gravitee_services_heartbeat_enabled=false
# Ceci est un bridge, donc nous avons bespoin du service correspondant.
gravitee_services_bridge_http_enabled=true
gravitee_services_bridge_http_port=18092
gravitee_services_bridge_http_host=0.0.0.0
gravitee_services_bridge_http_authentication_type=basic
{{ with secret "gravitee/gateway-bridge" }}gravitee_services_bridge_http_authentication_users_{{.Data.data.login}}={{.Data.data.password}}{{end}}
EOD
                destination = "secrets/.env"
                env = true
            }

            service {
                name = "$\u007BNOMAD_JOB_NAME\u007D"
                tags = ["urlprefix-${apim_gateway_bridge_fqdn}/"]
                port = "bridge-port"
                check {
                    name         = "alive"
                    type         = "tcp"
                    interval     = "10s"
                    timeout      = "5s"
                    port         = "bridge-port"
                }
            }
        }
    }
}
