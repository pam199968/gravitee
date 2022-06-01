project = "gravitee/apim-management-api"

# Labels can be specified for organizational purposes.
labels = { "domaine" = "gravitee" }

runner {
    enabled = true   
    data_source "git" {
        url  = "https://github.com/erickriegel/gravitee.git"
        ref  = var.datacenter
        path = "apim-management-api"
        ignore_changes_outside_path = true
    }
    poll {
        enabled = false
        interval = "24h"
    }
}
# An application to deploy.
app "gravitee/apim-management-api" {

    build {
        use "docker-pull" {
            image = "graviteeio/apim-management-api"
            tag   = "3.10.15"
            disable_entrypoint = true
        }
    }

    # Deploy to Nomad
    deploy {
        use "nomad-jobspec" {
            jobspec = templatefile("${path.app}/gravitee-apim-management-api.nomad.tpl", {
                datacenter = var.datacenter
		apim_api_fqdn = var.apim_api_fqdn
		user_java_opts = var.user_java_opts
		image = "graviteeio/apim-management-api"
		tag = "3.10.15"
            })
        }
    }
}

variable "datacenter" {
    type = string
    default = "henix_docker_platform_dev"
}

variable "apim_api_fqdn" {
	type = string
	default = "apimgmt.esante.gouv.fr"
}

variable "user_java_opts" {
	type = string
	default = ""
}
