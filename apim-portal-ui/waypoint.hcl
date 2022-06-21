project = "gravitee/apim-portal-ui"

# Labels can be specified for organizational purposes.
labels = { "domaine" = "gravitee" }

runner {
    enabled = true   
    data_source "git" {
        url  = "https://github.com/erickriegel/gravitee.git"
        ref  = "var.datacenter"
        path = "apim-portal-ui"
        ignore_changes_outside_path = true
    }
    poll {
        enabled = false
        interval = "24h"
    }
}
# An application to deploy.
app "gravitee/apim-portal-ui" {

    build {
        use "docker-pull" {
			image = "graviteeio/apim-portal-ui"
			tag   = "3.15.9"
			disable_entrypoint = true
        }
    }

    # Deploy to Nomad
    deploy {
        use "nomad-jobspec" {
            jobspec = templatefile("${path.app}/gravitee-apim-portal-ui.nomad.tpl", {
                datacenter = var.datacenter
				portal_ui_fqdn = var.portal_ui_fqdn
				image = "graviteeio/apim-portal-ui"
				tag = "3.15.9"
            })
        }
    }
}

variable "datacenter" {
    type = string
    default = "henix_docker_platform_dev"
}

variable "portal_ui_fqdn" {
	type = string
	default = "apimportalui.esante.gouv.fr"
}
