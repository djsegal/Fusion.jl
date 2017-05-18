@testset "Omega Pe2 Function Tests" begin

  @test isdefined(Tokamak, :omega_pe2) == true

  Tokamak.load_input(" Z_eff = 1.0 ")
  Tokamak.load_input(" n_bar = 0.86 * 1u\"n20\" ")
  Tokamak.load_input(" T_k = 17.8 * 1u\"keV\" ")

  cur_solved_R_0 = 4.0
  cur_solved_B_0 = 10.0

  test_hash = Dict(
    0.0 => 3.5598e23,
    0.5 => 3.2655e23,
    1.0 => 0.0
  )

  for (cur_key, expected_value) in test_hash
    actual_value = Tokamak.omega_pe2(cur_key)

    @test isapprox(expected_value, actual_value, rtol=5e-4)
  end

end
