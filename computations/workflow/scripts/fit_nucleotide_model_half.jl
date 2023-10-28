using MaxEntNucleotideBiases
using DataFrames
using CSV

if abspath(PROGRAM_FILE) == @__FILE__
    infile_data = ARGS[1]
    infile_bool = ARGS[2]
    family = ARGS[3]
    host = ARGS[4]

# collect data from infile_data and take training set
    data_df = DataFrame(CSV.File(infile_data))
    training_poss = parse.(Bool, readlines(infile_bool))
    training_seqs = data_df[training_poss, "halfsequence_train"]

    # train model
    model = MaxEntNucleotideBiases.fitmodel(training_seqs, 3, 5000)

    # save model
    repl = split(split(infile_bool, "_")[end], ".")[1]
    outfile = "results/models/$(family)_$(host)_NucleotideModel_half_$(repl).txt"
    MaxEntNucleotideBiases.writemodel(outfile, model)

end