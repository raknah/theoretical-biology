PARTRAC_PARAMS = Dict(
  :proton => (p1=6.8, p2=37.22, p3=0.6415, p4=7.099, p5=4.083),
  :helium => (p1=6.8, p2=10.56, p3=0.6902, p4=1.331, p5=1.317),
  :heavy  => (p1=6.8, p2=9.604, p3=0.6996, p4=1.425, p5=1.318),
)

function partracDSByield(LET::Float64, species::Symbol)
    p = PARTRAC_PARAMS[species]
    num = p.p1 + (p.p2 * LET)^p.p3
    den = 1 + (p.p4 * LET)^p.p5
    return num/den
end