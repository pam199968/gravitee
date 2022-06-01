job "gravitee-apim-management-ui" {

    type = "service"

    datacenters = ["${datacenter}"]

    update {
        stagger = "30s"
        max_parallel = 1
    }
	
	group "gravitee-apim-management-ui" {
		count = "1"
		# install only on "data" nodes
		restart {
			attempts = 3
			delay = "10s"
			interval = "1h"
			mode = "fail"
		}
		network {
			mode = "host"
			port "ui" { to = 8080 }
		}
		task "gravitee-management-ui" {
			driver = "docker"
			config {
				image = "${image}:${tag}"
				ports = ["ui"]
				volumes = [
				   "logs/apim-management-ui:/var/log/nginx"
				]
			}
			resources {
				cpu = 500
				memory = 1000
			}
			
			service {
				name = "$\u007BNOMAD_JOB_NAME\u007D"
				tags = ["urlprefix-${apim_ui_fqdn}/"]
				port = "ui"
				check {
					name        = "alive"
					type        = "http"
					interval    = "10s"
					timeout     = "5s"
					port        = "ui"
					path        = "/"
				}
			}
			template{
				data = <<EOH
				MGMT_API_URL=http://{{ range service "gravitee-apim-management-api" }}{{.ServiceMeta.fqdn}}{{end}}/management/organizations/DEFAULT/environments/DEFAULT/
				EOH
				destination = "local/file.env"
				env = true
			}
		}
	}
}
