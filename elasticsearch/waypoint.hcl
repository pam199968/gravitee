project = "gravitee/elasticsearch"

# Labels can be specified for organizational purposes.
labels = { "domaine" = "gravitee" }

runner {
    enabled = true   
    data_source "git" {
        url  = "https://github.com/erickriegel/gravitee.git"
        ref  = "var.datacenter"
        path = "elasticsearch"
        ignore_changes_outside_path = true
    }
    poll {
        enabled = false
        interval = "24h"
    }
}
# An application to deploy.
app "gravitee/elasticsearch" {

    build {
        use "docker-pull" {
            image = "bitnami/elasticsearch"
            tag   = "7.17.2"
            disable_entrypoint = true
        }
    }

    # Deploy to Nomad
    deploy {
        use "nomad-jobspec" {
            jobspec = templatefile("${path.app}/gravitee-elasticsearch.nomad.tpl", {
                datacenter = var.datacenter
                image = "bitnami/elasticsearch"
                tag = "7.17.2"
                es_repo_fqdn = var.es_repo_fqdn
            })
        }
    }
}

variable "datacenter" {
    type = string
    default = "henix_docker_platform_dev"
}

variable "es_repo_fqdn" {
    type = string
    default = "apim-es.api.esante.gouv.fr"
}
