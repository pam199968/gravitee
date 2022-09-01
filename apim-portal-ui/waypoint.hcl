project = "gravitee/apim-portal-ui"

# Labels can be specified for organizational purposes.
labels = { "domaine" = "gravitee" }

runner {
    enabled = true   
    data_source "git" {
        url  = "https://github.com/ansforge/gravitee.git"
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
			tag   = "3.18.7"
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
				tag = "3.15.7"
            })
        }
    }
}

variable "datacenter" {
    type = string
    default = "dc1"
}

variable "portal_ui_fqdn" {
	type = string
	default = "apimportalui.esante.gouv.fr"
}
