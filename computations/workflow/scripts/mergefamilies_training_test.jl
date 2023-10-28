if abspath(PROGRAM_FILE) == @__FILE__
    # parse arguments
    path_infiles = ARGS[1]
    host = ARGS[2]
    seed = parse.(Int, ARGS[3])
    out_train = ARGS[4]
    out_test = ARGS[5]
    inputs = ARGS[6:end]

    # collect relevant files
    # all_train_files = [f for f in readdir(path_infiles) if occursin("train", f)]
    # c1 = occursin.(host, all_train_files)
    # c2 = occursin.("$(seed)", all_train_files)
    # c3 = .!(occursin.("all", all_train_files))
    # c4 = .!(occursin.("fewseqs", all_train_files))
    # train_files = all_train_files[c1 .& c2 .& c3 .& c4]
    # all_test_files = [f for f in readdir(path_infiles) if occursin("test", f)]
    # c1 = occursin.(host, all_test_files)
    # c2 = occursin.("$(seed)", all_test_files)
    # c3 = .!(occursin.("all", all_test_files))
    # c4 = .!(occursin.("fewseqs", all_test_files))
    # test_files = all_test_files[c1 .& c2 .& c3 .& c4]
    train_files = inputs
    test_files = [replace(tf, "_training_" => "_test_") for tf in train_files]

    # merge relevant files
    pre_all_train = [parse.(Bool, v) for v in readlines.(train_files)]
    all_train = any.([[v[i] for v in pre_all_train] for i in 1:length(pre_all_train[1])])
    pre_all_test = [parse.(Bool, v) for v in readlines.(test_files)]
    all_test = any.([[v[i] for v in pre_all_test] for i in 1:length(pre_all_test[1])])
    @assert sum(all_train .& all_test) == 0

    # write output files
    open(out_train, "w") do f
        [write(f, "$(t)\n") for t in all_train]
    end
    open(out_test, "w") do f
        [write(f, "$(t)\n") for t in all_test]
    end

end