using MaxEntNucleotideBiases
using DataFrames
using CSV

function predict_host_hostonly(seq::AbstractString, models::Dict{<:AbstractString, MaxEntNucleotideBiases.NucleotideModel})
    hosts = collect(keys(models))
    t_host_scores = [MaxEntNucleotideBiases.compute_loglikelihood(seq, models[h]) for h in hosts]
    host_probs_unnorm = exp.(t_host_scores .- maximum(t_host_scores))
    norm = sum(host_probs_unnorm)
    host_probs = host_probs_unnorm ./ norm
    return sort(collect(zip(hosts, host_probs)), by=x->x[2], rev=true)
end

function predict_host_virushost(seq::AbstractString, models::Dict{<:Tuple{AbstractString, AbstractString}, MaxEntNucleotideBiases.NucleotideModel}; output_best_viruses::Bool=false)
    hosts = unique(last.(keys(models)))
    viruses = unique(first.(keys(models)))
    t_host_scores = []
    best_viruses = []
    for h in hosts
        vir_scores = [MaxEntNucleotideBiases.compute_loglikelihood(seq, models[(v, h)]) for v in viruses]
        max_vs = maximum(vir_scores)
        push!(best_viruses, viruses[argmax(vir_scores)])
        @assert abs(exp(sort(vir_scores, rev=true)[2] - max_vs)) < abs(max_vs / 1e3)
        push!(t_host_scores, max_vs)
    end
    host_probs_unnorm = exp.(t_host_scores .- maximum(t_host_scores))
    norm = sum(host_probs_unnorm)
    host_probs = host_probs_unnorm ./ norm
    if output_best_viruses
        return sort(collect(zip(hosts, host_probs)), by=x->x[2], rev=true), sort(collect(zip(best_viruses, host_probs)), by=x->x[2], rev=true)
    else
        return sort(collect(zip(hosts, host_probs)), by=x->x[2], rev=true)
    end
end

function predict_host_givenvirus(seq::AbstractString, models::Dict{<:Tuple{AbstractString, AbstractString}, MaxEntNucleotideBiases.NucleotideModel})
    hosts = unique(last.(keys(models)))
    pre_virus = unique(first.(keys(models)))
    pre_virus = pre_virus[.!occursin.("noPB2", pre_virus)] # remove pre_virus entries that contain "noPB2"
    @assert length(pre_virus) == 1 "pre_virus = $(pre_virus)"
    virus = pre_virus[1]
    t_host_scores = [MaxEntNucleotideBiases.compute_loglikelihood(seq, models[(virus, h)]) for h in hosts]
    host_probs_unnorm = exp.(t_host_scores .- maximum(t_host_scores))
    norm = sum(host_probs_unnorm)
    host_probs = host_probs_unnorm ./ norm    
    return sort(collect(zip(hosts, host_probs)), by=x->x[2], rev=true)
end

if abspath(PROGRAM_FILE) == @__FILE__
    infile_data = ARGS[1]
    model_folder = ARGS[2]
    seq_mode = ARGS[3]
    host_mode = ARGS[4]
    seed = ARGS[5]
    outfile = ARGS[6]
    host_mode == "virushost" && (outfile_viruses = replace(outfile, "hosts" => "viruses"))

    # checks on the input
    @assert (seq_mode in ["full", "half", "fewfull"]) "seq_mode must be either 'full', 'half' or 'fewfull'"
    @assert (host_mode in ["hostonly", "virushost", "givenvirus"]) "host_mode must be either 'hostonly', 'virushost', or 'givenvirus'"

    # load seqs and fams
    data_df = DataFrame(CSV.File(infile_data))
    fams = data_df[:, "family"]
    if seq_mode == "half"
        seqs_to_infer = data_df[:, "halfsequence_test"]
    else
        seqs_to_infer = data_df[:, "sequence"]
    end

    # load models
    pre_mod_files = readdir(model_folder)
    c1 = occursin.(seed, last.(split.(pre_mod_files,"_")))
    c2 = occursin.(seq_mode, pre_mod_files)
    file_mods = pre_mod_files[c1 .& c2]
    if host_mode == "hostonly"
        file_mods_hostonly = file_mods[first.(split.(file_mods, "_")) .== "all"]
        nt_mods = Dict([split(f, "_")[2] => MaxEntNucleotideBiases.readmodel(joinpath(model_folder, f)) for f in file_mods_hostonly])
    elseif host_mode == "virushost"
        file_mods_virushost = file_mods[first.(split.(file_mods, "_")) .!= "all"]
        nt_mods = Dict([(split(f, "_")[1], split(f, "_")[2]) => MaxEntNucleotideBiases.readmodel(joinpath(model_folder, f)) for f in file_mods_virushost])
    elseif host_mode == "givenvirus"
        file_mods_givenvirus = file_mods[first.(split.(file_mods, "_")) .!= "all"]
        nt_mods = [Dict([(split(f, "_")[1], split(f, "_")[2]) => MaxEntNucleotideBiases.readmodel(joinpath(model_folder, f)) for f in file_mods_givenvirus[occursin.(fam, file_mods_givenvirus)]]) for fam in fams]
    end

    # infer hosts
    M = length(seqs_to_infer)
    inferred_hosts = fill(Tuple{String, Float64}[], M)
    inferred_viruses = fill(Tuple{String, Float64}[], M)
    Threads.@threads for i in 1:M
        if host_mode == "hostonly"
            inferred_hosts[i] = predict_host_hostonly(seqs_to_infer[i], nt_mods)
        elseif host_mode == "virushost"
            inferred_hosts[i], inferred_viruses[i] = predict_host_virushost(seqs_to_infer[i], nt_mods, output_best_viruses=true)
        elseif host_mode == "givenvirus"
            inferred_hosts[i] = predict_host_givenvirus(seqs_to_infer[i], nt_mods[i])
        end
    end

    # write results
    open(outfile, "w") do f
        for h_list in inferred_hosts
            ln = join([first.(h_list); last.(h_list)], ",")
            println(f, ln)
        end
    end
    if host_mode == "virushost"
        mkpath(dirname(outfile_viruses)) # create folder if it doesn't exist, as this is not taken care of by snakemake
        open(outfile_viruses, "w") do f
            for v_list in inferred_viruses
                ln = join([first.(v_list); last.(v_list)], ",")
                println(f, ln)
            end
        end
    end
end
