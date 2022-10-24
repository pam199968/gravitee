job "gravitee-apim-gateway" {

    type = "service"

    datacenters = ["${datacenter}"]

    update {
        stagger = "30s"
        max_parallel = 1
    }

    vault {
        policies = ["gravitee", "proxy", "metrics_extractor_mut"]
        change_mode = "restart"
    }
	
    group "apim-gateway" {
        count = 1
        network {
            mode = "host"
            port "gateway-port" { to = 8082 }
            port "core-port" { to = 18082 }
	    port "debug" { to = 5005 }
        }
		
        scaling {
            enabled = true
            min     = ${min_count}
            max     = ${max_count}

            policy {
                # On sélectionne l'instance la moins chargée de toutes les instances en cours,
                # on rajoute une instance (ou on en enlève une) si les seuils spécifiés
                # de charge de cpu sont franchis.
                cooldown = "${cooldown}"
                check "low_cpu" {
                    source = "prometheus"
                    query = "min(system_cpu_usage{_app='apim-gateway'})"
                    strategy "threshold" {
                        upper_bound = ${seuil_scale_in}
                        delta = -1
                    }
                }

                check "high_cpu" {
                    source = "prometheus"
                    query = "min(system_cpu_usage{_app='apim-gateway'})"
                    strategy "threshold" {
                        lower_bound = ${seuil_scale_out}
                        delta = 1
                    }
                }
            }
        }
		
        task "apim-gateway" {
	
	    artifact {
                source      = "http://repo.proxy-dev-forge.asip.hst.fluxus.net/artifactory/ext-release-local/io/gravitee/gravitee-resource-oauth2-provider-generic-1.16.2.zip"
                options {
		    archive = false
  		}
	    }
	    artifact {
	    	source	= "https://github.com/prosanteconnect/generate-VIHF/releases/download/v1.5.0/generateVIHF-1.5.0.zip"
		options {
			archive = false
		}
	    }
	    artifact {
	    	source = "http://repo.proxy-dev-forge.asip.hst.fluxus.net/artifactory/asip-snapshots/fr/ans/psc/generateVIHF/1.5-SNAPSHOT/JDV_J65-SubjectRole-DMP.xml"
	    }
	    artifact {
	    	source = "https://github.com/prosanteconnect/digitalsign-gravitee-resource/releases/download/v1.1/digitalsign-gravitee-resource-1.1.zip"
		options {
			archive = false
		}
	    }
	    artifact {
	    	source = "https://github.com/prosanteconnect/digitalsign-gravitee-policy/releases/download/v1.1.3/digitalsign-gravitee-policy-1.1.3.zip"
		options {
			archive = false
		}
	    }
	    artifact {
	    	source = "https://github.com/prosanteconnect/digitalsign-gravitee-resource-api/releases/download/v1.3/digital-sign-resource-api-1.3.jar"
		options {
			archive = false
		}
	    }
            driver = "docker"

            config {
                image = "${image}:${tag}"
                ports = ["gateway-port", "core-port", "debug"]
            
		mount {
			type = "bind"
			# override plugin with proxy compatible version
			target = "/opt/graviteeio-gateway/plugins/gravitee-resource-oauth2-provider-generic-1.16.1.zip"
			source = "local/gravitee-resource-oauth2-provider-generic-1.16.2.zip"
			readonly = false
			bind_options {
				propagation = "rshared"
				}
	  		}
		mount {
			type = "bind"
			target = "/opt/graviteeio-gateway/plugins/generateVIHF-1.5.0.zip"
			source = "local/generateVIHF-1.5.0.zip"
			readonly = false
			bind_options {
				propagation = "rshared"
				}
			}
		mount {
			type = "bind"
			target = "/opt/graviteeio-gateway/lib/ext/JDV_J65-SubjectRole-DMP.xml"
			source = "local/JDV_J65-SubjectRole-DMP.xml"
			readonly = false
			bind_options {
				propagation = "rshared"
				}
			}
		mount {
			type = "bind"
			target = "/opt/graviteeio-gateway/plugins/digitalsign-gravitee-resource-1.1.zip"
			source = "local/digitalsign-gravitee-resource-1.1.zip"
			readonly = false
			bind_options {
				propagation = "rshared"
				}
			}
		mount {
			type = "bind"
			target = "/opt/graviteeio-gateway/plugins/digitalsign-gravitee-policy-1.1.3.zip"
			source = "local/digitalsign-gravitee-policy-1.1.3.zip"
			readonly = false
			bind_options {
				propagation = "rshared"
				}
			}
		mount {
			type = "bind"
			target = "/opt/graviteeio-gateway/lib/digital-sign-resource-api-1.3.jar"
			source = "local/digital-sign-resource-api-1.3.jar"
			readonly = false
			bind_options {
				propagation = "rshared"
				}
			}
		}


            resources {
                cpu = 1000
                memory = 2000
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
# proxy inter SI
gravitee_system_proxy_type=HTTP
gravitee_system_proxy_host={{ with secret "services-infrastructure/proxy" }}{{.Data.data.host}}{{end}}
gravitee_system_proxy_port={{ with secret "services-infrastructure/proxy" }}{{.Data.data.port}}{{end}}
# prometheus
gravitee_services_core_http_enabled=true
gravitee_services_core_http_host=0.0.0.0
gravitee_services_core_http_authentication_users_{{ with secret "services-infrastructure/metrics_extractor_mut" }}{{.Data.data.auth_username}}{{end}}={{ with secret "services-infrastructure/metrics_extractor_mut" }}{{.Data.data.auth_password}}{{end}}
gravitee_services_core_http_authentication_users_admin=
gravitee_services_metrics_enabled=true
_JAVA_OPTIONS="-Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=0.0.0.0:5005"
# Le heartbeat est en doublon avec Nomad et se marie mal avec l'allocation dynamique
gravitee_services_heartbeat_enabled=true
EOD
                destination = "secrets/.env"
                env = true
            }
	    
	    env = {
                "groovy.whitelist.mode" = "append"
                "groovy.whitelist.list[0]" = "class groovy.util.slurpersupport.Node"
                "groovy.whitelist.list[1]" = "class groovy.util.slurpersupport.NodeChild"
                "groovy.whitelist.list[2]" = "class groovy.util.XmlSlurper"
                "groovy.whitelist.list[3]" = "class groovy.util.XmlParser"
                "groovy.whitelist.list[4]" = "class groovy.util.slurpersupport.GPathResult"
	    }

            service {
                name = "$\u007BNOMAD_JOB_NAME\u007D"
				tags = ["urlprefix-${apim_gateway_fqdn}/"]
                port = "gateway-port"
                check {
                    name         = "alive"
                    type         = "tcp"
                    interval     = "10s"
                    timeout      = "5s"
                    port         = "gateway-port"
                }
            }
			
			service {
				name = "metrics-exporter-auth"
				port = "core-port"
				tags = ["_endpoint=/_node/metrics/prometheus", "_app=apim-gateway"]
			}
        }
    }
}
