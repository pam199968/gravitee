project = "gravitee/mongodb"

labels = { "domaine" = "gravitee" }

runner {
    enabled = true
    data_source "git" {
        url  = "https://github.com/erickriegel/gravitee.git"
        ref  = "var.datacenter"
        path = "mongodb"
        ignore_changes_outside_path = true
    }
    poll {
        enabled = false
        interval = "24h"
    }
}

app "gravitee/mongodb" {

    build {
        use "docker-pull" {
            image = "mongo"
            tag   = "4.4"
            disable_entrypoint = true
        }
    }

    deploy {
        use "nomad-jobspec" {
            jobspec = templatefile("${path.app}/gravitee-mongodb.nomad.tpl", {
                datacenter = var.datacenter
				image = "mongo"
				tag   = "4.4"
            })
		}
	}
}

variable "datacenter" {
    type  = string
  default = "henix_docker_platform_dev"
}
