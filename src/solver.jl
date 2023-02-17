"""
    waveguide_evolution(tspan, psi0, H; fout)

Integrate time-dependent Schroedinger equation to evolve states or compute propagators.
# Arguments
* `tspan`: Vector specifying the points of time for which output should be displayed.
* `psi0`: Initial state vector can only be a ket.
* `H`: Operator containing a [`WaveguideOperator`](@ref) either through a LazySum or LazyTensor.
* `fout=nothing`: If given, this function `fout(t, psi)` is called every time step. Example: `fout(t,psi) = expect(A,psi)` will return the epectation value of A at everytimestep. 
   ATTENTION: The state `psi` is neither normalized nor permanent! It is still in use by the ode solver and therefore must not be changed.

# Output
* if `fout=nothing` the output of the solver will be the state `ψ` at the last timestep. 
* if `fout` is given a tuple with the state `ψ` at the last timestep and the output of `fout` is given. If `fout` returns a tuple the tuple will be flattened.
Example `fout(t,psi) = (expect(A,psi),expect(B,psi))` will result in  a tuple (ψ, ⟨A(t)⟩,⟨B(t)⟩), where `⟨A(t)⟩` is a vector with the expectation value of `A` as a function of time.
"""
function waveguide_evolution(times,psi,H;fout=nothing)
    ops = get_waveguide_operators(H)
    dt = times[2] - times[1]
    tend = times[end]
    function get_hamiltonian(time,psi)
        #index = findlast(times .<= time)
        #basis.timeindex = index
        set_waveguidetimeindex!(ops,round(Int,time/dt,RoundUp)+1)
        #[op.timeindex = round(Int,time/dt,RoundUp)+1 for op in ops]
        #basis.timeindex = round(Int,time/dt,RoundUp)+1
        return H
    end
    function eval_last_element(time,psi)
        if time == tend
            return psi
        else
            return psi
        end
    end
    if fout === nothing
        tout, ψ = timeevolution.schroedinger_dynamic(times, psi, get_hamiltonian,fout=eval_last_element)
        #tout, ψ = timeevolution.schroedinger_dynamic(times, psi, get_hamiltonian)
        return ψ[end]
        #return ψ
    else
        function feval(time,psi)
            if time == tend
                return (psi,fout(time,psi)...)
            else
                return (0,fout(time,psi)...)
            end
        end
        tout, ψ = timeevolution.schroedinger_dynamic(times, psi, get_hamiltonian,fout=feval)
        return (ψ[end][1], [[ψ[i][j] for i in 1:length(times)] for j in 2:length(ψ[1])]...)
        #return ([[ψ[i][j] for i in 1:length(times)] for j in 1:length(ψ[1])]...,)
    end
end
#,alg=RK4(),dt=(times[2]-times[1])/2,adaptive=false
    
"""
    waveguide_montecarlo(times,psi,H,J;fout=nothing)
"""
function waveguide_montecarlo(times,psi,H,J;fout=nothing,kwargs...)
    ops = get_waveguide_operators(H)
    jops = get_waveguide_operators(J)
    dt = times[2] - times[1]
    tend = times[end]
    Jdagger = dagger.(J)
    #expect_ops = [LazyProduct(Jdagger[i],J[i]) for i in eachindex(J)]
    #rates = [expect(nj,psi) for nj in expect_ops]
    function get_hamiltonian(time,psi)
        set_waveguidetimeindex!(ops,round(Int,time/dt,RoundUp)+1)
        set_waveguidetimeindex!(jops,max(round(Int,time/dt,RoundUp),1))
        set_waveguidetimeindex!(Jdagger,max(round(Int,time/dt,RoundUp),1))
        #rates .= [expect(nj,psi)*dt for nj in expect_ops]
        #println(get_waveguidetimeindex(ops))
        #println(get_waveguidetimeindex(jops))
        #println(get_waveguidetimeindex(Jdagger))
        
        return (H,J,Jdagger,rates)
    end
    function eval_last_element(time,psi)
        if time == tend
            return psi
        else
            return psi
        end
    end
    if fout === nothing
        tout, ψ = timeevolution.mcwf_dynamic(times, psi, get_hamiltonian,fout=eval_last_element,kwargs...)
        return ψ[end]
    else
        function feval(time,psi)
            if time == tend
                return (psi,fout(time,psi)...)
            else
                return (0,fout(time,psi)...)
            end
        end
        tout, ψ = timeevolution.mcwf_dynamic(times, psi, get_hamiltonian;fout=feval,kwargs...)
        return (ψ[end][1], [[ψ[i][j] for i in 1:length(times)] for j in 2:length(ψ[1])]...)
        #return ([[ψ[i][j] for i in 1:length(times)] for j in 1:length(ψ[1])]...,)
    end
end