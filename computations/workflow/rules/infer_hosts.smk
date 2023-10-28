ruleorder: infer_hosts_all > infer_hosts

rule infer_hosts:
    message:
        "Inferring hosts of train and test sequences, sequence mode: {wildcards.seq_mode}; host mode: {wildcards.host_mode}; seed: {wildcards.seed}."
    input:
        expand("results/models/{family}_{host}_NucleotideModel_{{seq_mode}}_{{seed}}.txt", 
                family=config["viral_families"], 
                host=config["viral_hosts"])
    output:
        "results/inferred_hosts/{seq_mode}_{host_mode}_{seed}.txt"
    threads: 8
    params:
        data_file = config["data_file"]
    shell:
        """
        julia -t {threads} --project=workflow/envs/Project.toml workflow/scripts/infer_hosts.jl {params.data_file} results/models/ {wildcards.seq_mode} {wildcards.host_mode} {wildcards.seed} {output}
        """


rule infer_hosts_all:
    message:
        "Inferring hosts of train and test sequences, sequence mode: {wildcards.seq_mode}; host mode: hostonly; seed: {wildcards.seed}."
    input:
        expand("results/models/all_{host}_NucleotideModel_{{seq_mode}}_{{seed}}.txt", 
                host=config["viral_hosts"])
    output:
        "results/inferred_hosts/{seq_mode}_hostonly_{seed}.txt"
    threads: 8
    params:
        data_file = config["data_file"]
    shell:
        """
        julia -t {threads} --project=workflow/envs/Project.toml workflow/scripts/infer_hosts.jl {params.data_file} results/models/ {wildcards.seq_mode} hostonly {wildcards.seed} {output}
        """
