job "gravitee-apim-management-api" {

    type = "service"

    datacenters = ["${datacenter}"]

    update {
        stagger = "30s"
        max_parallel = 1
    }

    vault {
        policies = ["gravitee","smtp"]
        change_mode = "restart"
    }
	
    group "apim-management-api" {
        count = 1
        network {
			mode = "host"
            port "apim-manager-api" { to = 8083 }
        }
        task "apim-management-api" {
	
	    artifact {
                source      = "http://repo.proxy-dev-forge.asip.hst.fluxus.net/artifactory/ext-release-local/io/gravitee/gravitee-resource-oauth2-provider-generic-1.16.2.zip"
                options {
    			archive = false
  		}
	    }
	    
	    artifact {
	    	source	= "http://repo.proxy-dev-forge.asip.hst.fluxus.net/artifactory/asip-snapshots/fr/ans/psc/generateVIHF/1.5-SNAPSHOT/generateVIHF-1.5-SNAPSHOT.zip"
		options {
			archive = false
		}
	    }
	    artifact {
	    	source	= "http://repo.proxy-dev-forge.asip.hst.fluxus.net/artifactory/asip-snapshots/fr/ans/psc/digitalsign-gravitee-resource/1.1-SNAPSHOT/digitalsign-gravitee-resource-1.1-SNAPSHOT.zip"
		options {
			archive = false
		}
	    }
	    artifact {
	    	source	= "http://repo.proxy-dev-forge.asip.hst.fluxus.net/artifactory/asip-snapshots/fr/ans/psc/digitalsign-gravitee-policy/1.1.3-SNAPSHOT/digitalsign-gravitee-policy-1.1.3-SNAPSHOT.zip"
		options {
			archive = false
		}
	    }
	    artifact {
	    	source = "http://repo.proxy-dev-forge.asip.hst.fluxus.net/artifactory/asip-snapshots/fr/ans/psc/digital-sign-resource-api/1.3-SNAPSHOT/digital-sign-resource-api-1.3-SNAPSHOT.jar"
		options {
			archive = false
		}
	    }
            driver = "docker"

            config {
                image = "${image}:${tag}"
                ports = ["apim-manager-api"]

		mount {
			type = "bind"
			# override plugin with proxy compatible version
			target = "/opt/graviteeio-management-api/plugins/gravitee-resource-oauth2-provider-generic-1.16.1.zip"
			source = "local/gravitee-resource-oauth2-provider-generic-1.16.2.zip"
			readonly = false
			bind_options {
				propagation = "rshared"
			}
		}
		
		mount {
			type = "bind"
			target = "/opt/graviteeio-management-api/plugins/generateVIHF-1.5-SNAPSHOT.zip"
			source = "local/generateVIHF-1.5-SNAPSHOT.zip"
			readonly = false
			bind_options {
				propagation = "rshared"
			}
		}
		mount {
			type = "bind"
			target = "/opt/graviteeio-management-api/plugins/digitalsign-gravitee-resource-1.1-SNAPSHOT.zip"
			source = "local/digitalsign-gravitee-resource-1.1-SNAPSHOT.zip"
			readonly = false
			bind_options {
				propagation = "rshared"
			}
		}
		mount {
			type = "bind"
			target = "/opt/graviteeio-management-api/plugins/digitalsign-gravitee-policy-1.1.3-SNAPSHOT.zip"
			source = "local/digitalsign-gravitee-policy-1.1.3-SNAPSHOT.zip"
			readonly = false
			bind_options {
				propagation = "rshared"
			}
		}
		mount {
			type = "bind"
			target = "/opt/graviteeio-management-api/lib/digital-sign-resource-api-1.3-SNAPSHOT.jar"
			source = "local/digital-sign-resource-api-1.3-SNAPSHOT.jar"
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
gravitee.management.mongodb.host = {{ range service "gravitee-mongodb" }}{{.Address}}{{end}}
gravitee.management.mongodb.port = {{ range service "gravitee-mongodb" }}{{.Port}}{{end}}
gravitee.management.mongodb.authSource  = admin
gravitee.management.mongodb.username = {{ with secret "gravitee/mongodb" }}{{.Data.data.root_user}}{{end}}
gravitee.management.mongodb.password = {{ with secret "gravitee/mongodb" }}{{.Data.data.root_pass}}{{end}}
gravitee_analytics_elasticsearch_endpoints_0=http://{{ range service "gravitee-elasticsearch" }}{{.Address}}:{{.Port}}{{end}}

gravitee.analytics.elasticsearch.security.username={{ with secret "gravitee/elasticsearch" }}{{.Data.data.root_user}}{{end}}
gravitee.analytics.elasticsearch.security.password={{ with secret "gravitee/elasticsearch" }}{{.Data.data.root_pass}}{{end}}
# Default admin override
gravitee_security_providers_0_users_1_username={{ with secret "gravitee/apim" }}{{.Data.data.admin_username}}{{end}}
gravitee_security_providers_0_users_1_password={{ with secret "gravitee/apim" }}{{.Data.data.admin_password}}{{end}}
# Other default users disabling
gravitee_security_providers_0_users_0_password=
gravitee_security_providers_0_users_2_password=
gravitee_security_providers_0_users_3_password=
gravitee_email_enabled=true
gravitee_email_host={{ with secret "services-infrastructure/smtp" }}{{.Data.data.host}}{{end}}
gravitee_email_port={{ with secret "services-infrastructure/smtp" }}{{.Data.data.port}}{{end}}
gravitee_email_from=noreply@${apim_api_fqdn}
# jwt secret override
gravitee_jwt_secret={{ with secret "gravitee/apim" }}{{.Data.data.jwt_secret}}{{end}}
# api properties encryption secret override
gravitee_api_properties_encryption_secret={{ with secret "gravitee/apim" }}{{.Data.data.encryption_secret}}{{end}}
_JAVA_OPTIONS="${user_java_opts}"
# Disabling newsletter from apim management api to avoid this 10s request that times out 
# at first connection
gravitee_newsletter_enabled=false
# Gateway related management parameters
gravitee.gateway.unknown.expire.after=1
# Fermeture de l'API interne APIM qui n'est pas utilisée.
gravitee_service_core_http_enabled=false
EOD
                destination = "secrets/.env"
                env = true
            }

            service {
                name = "$\u007BNOMAD_JOB_NAME\u007D"
                tags = ["urlprefix-${apim_api_fqdn}/"]
                port = "apim-manager-api"
                meta {
                    fqdn = "${apim_api_fqdn}"
                }
                check {
                    name        = "alive"
                    type        = "http"
                    interval    = "10s"
                    timeout     = "5s"
                    port 	= "apim-manager-api"
                    path        = "management/organizations/DEFAULT/console" 
                }
            }
        }
    }
}
