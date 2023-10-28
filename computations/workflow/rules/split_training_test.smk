
ruleorder: mergefamilies_training_test > split_training_test

rule split_training_test:
    message:
        "Splitting data in training and test set, viral family: {wildcards.family}; host: {wildcards.host}; seed: {wildcards.seed}."
    output:
        train = "resources/training_sets/{family}_{host}_training_{seed,\d+}.txt",
        test = "resources/training_sets/{family}_{host}_test_{seed,\d+}.txt"
    threads: 1
    params:
        data_file = config["data_file"],
        train_n = config["training_sequence_number"],
        test_n = config["test_sequence_number"]
    shell:
        """
        julia --project=workflow/envs/Project.toml workflow/scripts/split_training_test.jl {params.data_file} {wildcards.family} {wildcards.host} {wildcards.seed} {params.train_n} {params.test_n} {output.train} {output.test}
        """

rule mergefamilies_training_test:
    message:
        "Merging all family training and test sets to create 'all' for host {wildcards.host} and seed {wildcards.seed}."
    input:
        expand("resources/training_sets/{family}_{{host}}_training_{{seed}}.txt",
        family = config["viral_families"]
        )
    output:
        train = "resources/training_sets/all_{host}_training_{seed,\d+}.txt",
        test = "resources/training_sets/all_{host}_test_{seed,\d+}.txt"
    threads: 1
    shell:
        """
        julia --project=workflow/envs/Project.toml workflow/scripts/mergefamilies_training_test.jl \
        resources/training_sets {wildcards.host} {wildcards.seed} {output.train} {output.test} {input}
        """