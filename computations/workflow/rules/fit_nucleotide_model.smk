
rule fit_nucleotide_model_full:
    message:
        "Fitting nucleotide model on full sequences, viral family: {wildcards.family}; host: {wildcards.host}; repl: {wildcards.repl}."
    input:
        "resources/training_sets/{family}_{host}_training_{repl}.txt"
    output:
        "results/models/{family}_{host}_NucleotideModel_full_{repl}.txt"
    threads: 1
    params:
        data_file = config["data_file"]
    shell:
        """
        julia --project=workflow/envs/Project.toml workflow/scripts/fit_nucleotide_model_full.jl {params.data_file} {input} {wildcards.family} {wildcards.host} {output}
        """

rule fit_nucleotide_model_half:
    message:
        "Fitting nucleotide model on half sequences, viral family: {wildcards.family}; host: {wildcards.host}; repl: {wildcards.repl}."
    input:
        "resources/training_sets/{family}_{host}_training_{repl}.txt"
    output:
        "results/models/{family}_{host}_NucleotideModel_half_{repl}.txt"
    threads: 1
    params:
        data_file = config["data_file"]
        #data_file = choose_data_file
    shell:
        """
        julia --project=workflow/envs/Project.toml workflow/scripts/fit_nucleotide_model_half.jl {params.data_file} {input} {wildcards.family} {wildcards.host}
        """