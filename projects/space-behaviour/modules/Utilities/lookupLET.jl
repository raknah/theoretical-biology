using CSV
using DataFrames
using Interpolations

datapath = "/Users/fomo/Documents/Kaizen/code/space-behaviour/data/stopping-power"

function loadLETfromNIST(filepath; use_total = false, density = 1.0)
    df = CSV.read(
    joinpath(datapath, filepath), 
    DataFrame;
    header = 8,
    delim='\t', 
    ignorerepeated=true
    )

    rename!(df, Dict(
        names(df)[1] => "energy_MeV",
        names(df)[2] => "electron_MeVcm2g",
        names(df)[3] => "nuclear_MeVcm2g",
        names(df)[4] => "total_MeVcm2g"
    ))

    for col in names(df)
        df[!, col] = Float64.(df[!, col])
    end

    colname = use_total ? "total_MeVcm2g" : "electron_MeVcm2g"

    LET_keV_per_μm = df[!, colname] .* density .* 0.1

    return LinearInterpolation(df.energy_MeV, LET_keV_per_μm, extrapolation_bc=Flat())

end


function loadLETfromSRIM(filepath; density = 1.0)

    df = CSV.read(
        joinpath(datapath, filepath),
        DataFrame;
        header = 0,
        delim = "\t",
        ignorerepeated = true
        )

    rename!(df, Dict(
        names(df)[1] => "Energy (MeV)",
        names(df)[2] => "Stopping Power (MeV cm2 g-1)",
        names(df)[3] => "Ionising Dose (MeV g-1)",
        names(df)[4] => "Ionising Dose (Gy)"
    ))

    for col in names(df)
        df[!, col] = Float64.(df[!, col])
    end   

    LET_keV_per_μm = df[!, "Stopping Power (MeV cm2 g-1)"] .* density .* 0.1


    return LinearInterpolation(df[:, "Energy (MeV)"], LET_keV_per_μm, extrapolation_bc=Flat())
end


