using JuMP
using HiGHS

# Date de intrare
Alimente = ["Branza", "Cascaval", "Iaurt", "Lapte", "Unt"]
A = length(Alimente)
Fabrici = ["F1", "F2", "F3"]
F = length(Fabrici)
Magazine = ["M1", "M2"]
M = length(Magazine)

ProducerePerOra = [15 10 12 15 10;
                   10 15 18 13 12;
                   13 18 15 10 11]  # Cantitatea de produse pe care fiecare fabrică o produce într-o oră pentru fiecare aliment

H = 8  # Numărul de ore lucrate

CapacitateaFabricii = [200; 250; 150]  # Capacitatea de producție a fabricilor per total

CerereMagazine = [30 40 20 60 55;
                  60 30 40 20 35]

CosturiProdus = [17 18 13 10 12;
                 20 16 14 8 11;
                 16 19 15 9 10]  # Matricea costurilor pentru fiecare produs și fabrică

# Model
model = Model(HiGHS.Optimizer)  # Utilizăm HiGHS Optimizer 

@variable(model, x[f = 1:F, a = 1:A] >= 0, Int)  # Cantitatea de alimente produsă
@variable(model, t[f = 1:F, m = 1:M, a = 1:A] >= 0, Int)  # Cantitatea de alimente transportată de la fiecare fabrică la fiecare magazin
@variable(model, c[f = 1:F, a = 1:A] >= 0)  # Costul fiecărei combinații de fabrică și aliment

@objective(model, Min, sum(c[f, a] for f in 1:F, a in 1:A))  # Minimizarea costului total al fabricilor

@constraint(model, [f = 1:F], sum(x[f, a] for a in 1:A) <= CapacitateaFabricii[f])
@constraint(model, [f = 1:F, a = 1:A], x[f, a] <= ProducerePerOra[f, a] * H)

# Constrângeri pentru transport
@constraint(model, [m = 1:M, a = 1:A], sum(t[f, m, a] for f in 1:F) == CerereMagazine[m, a])  # Cererea magazinelor trebuie să fie satisfăcută
@constraint(model, [m = 1:M, a = 1:A], sum(t[f, m, a] for f in 1:F) <= sum(x[f, a] for f in 1:F))  # Cantitatea transportată nu poate depăși cantitatea produsă
@constraint(model, [f = 1:F, m = 1:M, a = 1:A], t[f, m, a] <= x[f, a])  # Cantitatea transportată nu poate depăși disponibilitatea din fabrică

@constraint(model, [f = 1:F, a = 1:A], x[f, a] >= 1) # Cantitate minimă produsă în fiecare fabrică

@constraint(model, [f = 1:F, a = 1:A], c[f, a] == CosturiProdus[f, a] * x[f, a])  # Relația cost - cantitate

# Rezolvare
optimize!(model)
println("Status final: ", termination_status(model))

if termination_status(model) == MOI.OPTIMAL
    println("Valoarea funcției obiectiv: ", objective_value(model))

    @expression(model, total_cost, sum(c[f, a] * value(x[f, a]) for f in 1:F, a in 1:A))  # Expresie pentru costul total
    println("Costul total al produselor: ", JuMP.value(total_cost), "\n")

    for f in 1:F
        println("Produsele produse în fabrica ", Fabrici[f], ":")
        for a in 1:A
            if value(x[f, a]) > 0.1  # Printează alimentele produse
                println("Au fost produse ", round(Int64, value(x[f, a])), " bucăți de ", Alimente[a], " cu un cost de ", round(value(c[f, a]), digits = 2))
            end
        end
        println()
    end

    for f in 1:F
        for m in 1:M
            println("\nProdusele transportate de la fabrica ", Fabrici[f], " la magazinul ", Magazine[m], ":")
            for a in 1:A
                if value(t[f, m, a]) > 0.1  # Printează alimentele transportate
                    println("Au fost transportate ", round(Int64, value(t[f, m, a])), " bucăți de ", Alimente[a])
                end
            end
        end
    end

else
    println("Nicio soluție disponibilă")
end
