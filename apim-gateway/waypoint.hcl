project = "gravitee/apim-gateway"

# Labels can be specified for organizational purposes.
labels = { "domaine" = "gravitee" }

runner {
    enabled = true   
    data_source "git" {
        url  = "https://github.com/erickriegel/gravitee.git"
        ref  = "var.datacenter"
        path = "apim-gateway"
        ignore_changes_outside_path = true
    }
    poll {
        enabled = false
        interval = "24h"
    }
}
# An application to deploy.
app "gravitee/apim-gateway" {

    build {
        use "docker-pull" {
            image = "graviteeio/apim-gateway"
            tag   = "3.15.9"
            disable_entrypoint = true
        }
    }

    # Deploy to Nomad
    deploy {
        use "nomad-jobspec" {
            jobspec = templatefile("${path.app}/gravitee-apim-gateway.nomad.tpl", {
                datacenter = var.datacenter
                user_java_opts = var.user_java_opts
                apim_gateway_fqdn = var.apim_gateway_fqdn
                image = "graviteeio/apim-gateway"
                tag = "3.15.9"
                min_count = var.min_count
                max_count = var.max_count
                cooldown = var.cooldown
                seuil_scale_in = var.seuil_scale_in
                seuil_scale_out = var.seuil_scale_out
            })
        }
    }
}

variable "datacenter" {
    type = string
    default = "henix_docker_platform_dev"
}

variable "user_java_opts" {
    type = string
    default = ""
}

variable "apim_gateway_fqdn" {
    type = string
    default = "apimgateway.esante.gouv.fr"
}

variable "min_count" {
    type = number
    default = 1
}

variable "max_count" {
    type = number
    default = 5
}

variable "cooldown" {
    type = string
    default = "180s"
}

variable "seuil_scale_in" {
    type = number
    default = 0.4
}

variable "seuil_scale_out" {
    type = number
    default = 0.95
}
