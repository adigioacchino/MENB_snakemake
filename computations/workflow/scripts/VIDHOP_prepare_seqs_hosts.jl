using DataFrames
using CSV

if abspath(PROGRAM_FILE) == @__FILE__
    # parse arguments
    infile = ARGS[1]
    path_traintest = ARGS[2]
    family = ARGS[3]
    seq_mode = ARGS[4]
    @assert (seq_mode in ["full", "half", "fewfull"]) "seq_mode must be either 'full', 'half' or 'fewfull'"
    seed = parse.(Int, ARGS[5])
    mode = ARGS[6]
    @assert mode in ["training", "test"]
    outfile_seqs = ARGS[7]
    outfile_hosts = ARGS[8]

    # collect data from infile
    data_df = DataFrame(CSV.File(infile))
    
    # collect relevant files
    all_relevant_files = [f for f in readdir(path_traintest) if occursin(mode, f)]
    c1 = occursin.(family, all_relevant_files)
    c2 = occursin.("$(seed)", all_relevant_files)
    relevant_files = all_relevant_files[c1 .& c2]

    # merge relevant files
    pre_all = [parse.(Bool, v) for v in readlines.(joinpath.(path_traintest, relevant_files))]
    seqs_bool = any.([[v[i] for v in pre_all] for i in 1:length(pre_all[1])])

    # prepare seqs and hosts
    if seq_mode == "half"
        pre_seqs = data_df[seqs_bool, "sequence"]
        if mode == "training"
            seqs = [s[1:round(Int, length(s)/2)] for s in pre_seqs]
        else
            seqs = [s[round(Int, length(s)/2)+1:end] for s in pre_seqs]
        end
    else
        seqs = data_df[seqs_bool, "sequence"]
    end
    hosts = data_df[seqs_bool, "host"]

    # write data on file
    open(outfile_seqs, "w") do io
        if mode == "training"
            [println(io, t) for t in seqs]
        else
            [println(io, "$(i)\t$(t)") for (i,t) in enumerate(seqs)]
        end
    end
    open(outfile_hosts, "w") do io
        if mode == "training"
            [println(io, t) for t in hosts]
        else
            [println(io, "$(i)\t$(t)") for (i,t) in enumerate(hosts)]
        end
    end

end