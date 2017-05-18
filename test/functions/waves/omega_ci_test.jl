@testset "Omega Ci Function Tests" begin

  @test isdefined(Tokamak, :omega_ci) == true

  Tokamak.load_input(" Z_eff = 1.0 ")
  Tokamak.load_input(" n_bar = 0.86 * 1u\"n20\" ")
  Tokamak.load_input(" T_k = 17.8 * 1u\"keV\" ")

  cur_solved_R_0 = 4.0
  cur_solved_B_0 = 10.0

  test_hash = Dict(
    0.0 => 3.8376e8,
    0.5 => 3.4112e8,
    1.0 => 3.0701e8
  )

  for (cur_key, expected_value) in test_hash
    actual_value = Tokamak.omega_ci(cur_key)

    actual_value = subs(
      actual_value, Tokamak.symbol_dict["B_0"], cur_solved_B_0
    )

    @test isapprox(expected_value, actual_value, rtol=5e-4)
  end

end
