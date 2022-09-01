project = "gravitee/apim-management-ui"

# Labels can be specified for organizational purposes.
labels = { "domaine" = "gravitee" }

runner {
    enabled = true   
    data_source "git" {
        url  = "https://github.com/ansforge/gravitee.git"
        ref  = "var.datacenter"
        path = "apim-management-ui"
        ignore_changes_outside_path = true
    }
    poll {
        enabled = false
        interval = "24h"
    }
}
# An application to deploy.
app "gravitee/apim-management-ui" {

    build {
        use "docker-pull" {
            image = "graviteeio/apim-management-ui"
            tag   = "3.18.7"
            disable_entrypoint = true
        }
    }

    # Deploy to Nomad
    deploy {
        use "nomad-jobspec" {
            jobspec = templatefile("${path.app}/gravitee-apim-management-ui.nomad.tpl", {
                datacenter = var.datacenter
                apim_ui_fqdn = var.apim_ui_fqdn
                user_java_opts = var.user_java_opts
                image = "graviteeio/apim-management-ui"
                tag = "3.15.7"
            })
        }
    }
}

variable "datacenter" {
    type = string
    default = "dc1"
}

variable "apim_ui_fqdn" {
	type = string
	default = "apimgmtui.esante.gouv.fr"
}

variable "user_java_opts" {
	type = string
	default = ""
}
