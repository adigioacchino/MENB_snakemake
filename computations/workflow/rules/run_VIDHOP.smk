# rule run_VIDHOP:
#     message:
#         "Running VIDHOP for family: {wildcards.family}, seq_mode: {wildcards.seq_mode}, seed: {wildcards.seed}."
#     input:
#         expand("resources/training_sets/{{family}}_{host}_{traintest}_{{seed}}.txt",
#                 host = config["viral_hosts"],
#                 traintest = ["training", "test"])
#     output:
#         "results/VIDHOP/{family}_{seq_mode}_{seed}.txt"
#     shadow: "minimal"
#     threads: 4
#     params:
#         data_file = config["data_file"]
#     conda:
#         "../envs/vidhop.yml"
#     run:
#         julia_vidhop_prepare_command = "julia --project=workflow/envs/Project.toml workflow/scripts/VIDHOP_prepare_seqs_hosts.jl {params.data_file} resources/training_sets {wildcards.family} {wildcards.seq_mode} {wildcards.seed}"
#         shell(julia_vidhop_prepare_command + " training")
#         shell("vidhop make_dataset -x training_seqs.txt -y training_hosts.txt -o trainingdata/ -t 0.0 -v 0.2")
#         shell(julia_vidhop_prepare_command + " test")
#         shell("vidhop training -i trainingdata/ -o ./ -a 1 > {output}")

rule prepare_training_VIDHOP:
    message:
        "Preparing training for VIDHOP; family: {wildcards.family}, seq_mode: {wildcards.seq_mode}, seed: {wildcards.seed}."
    input:
        expand("resources/training_sets/{{family}}_{host}_{traintest}_{{seed}}.txt",
                host = config["viral_hosts"],
                traintest = ["training", "test"])
    output:
        seqs = temp("resources/VIDHOP/{family}_{seq_mode}_{seed,\d+}_training_seqs.txt"),
        hosts = temp("resources/VIDHOP/{family}_{seq_mode}_{seed,\d+}_training_hosts.txt")
    threads: 1
    params:
        data_file = config["data_file"]
    shell:
        """
        julia --project=workflow/envs/Project.toml workflow/scripts/VIDHOP_prepare_seqs_hosts.jl {params.data_file} resources/training_sets {wildcards.family} {wildcards.seq_mode} {wildcards.seed} training {output.seqs} {output.hosts}
        """

rule make_dataset_VIDHOP:
    message:
        "Preparing datasets with VIDHOP; family: {wildcards.family}, seq_mode: {wildcards.seq_mode}, seed: {wildcards.seed}."
    input:
        seqs = "resources/VIDHOP/{family}_{seq_mode}_{seed}_training_seqs.txt",
        hosts = "resources/VIDHOP/{family}_{seq_mode}_{seed}_training_hosts.txt"
    output:
        "results/VIDHOP/{family}_{seq_mode}_{seed,\d+}_trainingdata/X_train.csv"
    threads: 1
    conda: # since a conda env is defined, each time this rule must be run the snakemake command must contain '--use-conda' option; I had to create the environment manually from the file workflow/envs/vidhop.yml as snakemake was stuck at the step "Downloading and installing remote packages." 
        "vidhop"
    shell:
        """
        vidhop make_dataset -x {input.seqs} -y {input.hosts} -o results/VIDHOP/{wildcards.family}_{wildcards.seq_mode}_{wildcards.seed}_trainingdata -t 0.0 -v 0.2
        """


rule prepare_test_VIDHOP:
    message:
        "Preparing test for VIDHOP; family: {wildcards.family}, seq_mode: {wildcards.seq_mode}, seed: {wildcards.seed}."
    input:
        "results/VIDHOP/{family}_{seq_mode}_{seed}_trainingdata/X_train.csv"
    output:
        seqs = "results/VIDHOP/{family}_{seq_mode}_{seed,\d+}_trainingdata/X_test.csv",
        hosts = "results/VIDHOP/{family}_{seq_mode}_{seed,\d+}_trainingdata/Y_test.csv",
        flag = touch("results/VIDHOP/{family}_{seq_mode}_{seed,\d+}_trainingdata/prepare_test.done")
    threads: 1
    params:
        data_file = config["data_file"]
    shell:
        """
        julia --project=workflow/envs/Project.toml workflow/scripts/VIDHOP_prepare_seqs_hosts.jl {params.data_file} resources/training_sets {wildcards.family} {wildcards.seq_mode} {wildcards.seed} test {output.seqs} {output.hosts}
        """


rule train_VIDHOP:
    message:
        "Training and testing VIDHOP; family: {wildcards.family}, seq_mode: {wildcards.seq_mode}, seed: {wildcards.seed}."
    input:
        "results/VIDHOP/{family}_{seq_mode}_{seed}_trainingdata/prepare_test.done"
    output:
        "results/VIDHOP/results/{family}_{seq_mode}_{seed,\d+}.txt"
    threads: workflow.cores
    conda: # since a conda env is defined, each time this rule must be run the snakemake command must contain '--use-conda' option; I had to create the environment manually from the file workflow/envs/vidhop.yml as snakemake was stuck at the step "Downloading and installing remote packages." 
        "vidhop"
    shell:
        """
        vidhop training -i results/VIDHOP/{wildcards.family}_{wildcards.seq_mode}_{wildcards.seed}_trainingdata/ --name {wildcards.family}{wildcards.seq_mode}{wildcards.seed} -o results/VIDHOP/models/ -a 1 > {output}
        """