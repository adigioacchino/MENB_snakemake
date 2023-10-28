using DataFrames
using CSV
using Random

if abspath(PROGRAM_FILE) == @__FILE__
    # parse arguments
    infile = ARGS[1]
    family = ARGS[2]
    host = ARGS[3]
    seed = parse.(Int, ARGS[4])
    train_n = parse.(Int, ARGS[5])
    test_n = parse.(Int, ARGS[6])
    outfile_train = ARGS[7]
    outfile_test = ARGS[8]

    # collect data from infile
    data_df = DataFrame(CSV.File(infile))
    c1 = data_df[:, "family"] .== family
    c2 = data_df[:, "host"] .== host
    seq_poss = findall(c1 .& c2)

    # use train_n seqs as training, test_n as test
    @assert length(seq_poss) >= train_n + test_n "Not enough sequences to build training and test sets!"
    rg = Xoshiro(seed)
    shuffle!(rg, seq_poss)
    train_poss = seq_poss[1:train_n]
    test_poss = seq_poss[train_n+1:train_n+test_n]

    # write output files
    train_bool = [(i in train_poss) for i in 1:nrow(data_df)]
    open(outfile_train,"w") do f
        [write(f, "$(t)\n") for t in train_bool]
    end
    test_bool = [(i in test_poss) for i in 1:nrow(data_df)]
    open(outfile_test,"w") do f
        [write(f, "$(t)\n") for t in test_bool]
    end

end