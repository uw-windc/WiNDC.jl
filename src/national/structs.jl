abstract type AbstractNationalTable <: WiNDCtable end

domain(data::AbstractNationalTable) = [:commodities, :sectors, :year]


struct NationalTable <: AbstractNationalTable
    table::DataFrame
    sets::DataFrame
end
