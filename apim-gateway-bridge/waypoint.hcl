project = "gravitee/apim-gateway-bridge"

# Labels can be specified for organizational purposes.
labels = { "domaine" = "gravitee" }

runner {
    enabled = true   
    data_source "git" {
        url  = "https://github.com/ansforge/gravitee.git"
        ref  = "var.datacenter"
        path = "apim-gateway-bridge"
        ignore_changes_outside_path = true
    }
    poll {
        enabled = false
        interval = "24h"
    }
}
# An application to deploy.
app "gravitee/apim-gateway-bridge" {

    build {
        use "docker-pull" {
            image = "graviteeio/apim-gateway"
            tag   = "3.18.7"
            disable_entrypoint = true
        }
    }

    # Deploy to Nomad
    deploy {
        use "nomad-jobspec" {
            jobspec = templatefile("${path.app}/gravitee-apim-gateway-bridge.nomad.tpl", {
                datacenter = var.datacenter
                user_java_opts = var.user_java_opts
                apim_gateway_bridge_fqdn = var.apim_gateway_bridge_fqdn
                image = "graviteeio/apim-gateway"
                tag = "3.15.7"
            })
        }
    }
}

variable "datacenter" {
    type = string
    default = "dc1"
}

variable "user_java_opts" {
	type = string
	default = ""
}

variable "apim_gateway_bridge_fqdn" {
	type = string
	default = "apimgw-bridge.esante.gouv.fr"
}
