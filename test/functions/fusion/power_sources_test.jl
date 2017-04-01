@testset "Power Sources Function Tests" begin

  @test isdefined(Tokamak, :power_sources) == true

  scale_factor = 1u"MW"
  scale_factor *= Sym("R_0") ^ 3
  scale_factor *= Sym("n_bar") ^ 2

  actual_value = Tokamak.power_sources()
  actual_value /= scale_factor

  expected_value = Tokamak.P_F()
  expected_value *= 5 + Tokamak.Q
  expected_value /= 5 * Tokamak.Q
  expected_value /= scale_factor

  @test isapprox( expected_value , actual_value , rtol=1e-2)

  expected_value = 6.888
  expected_value *= ( Tokamak.sigma_v_hat() / 1u"m^3/s" )

  @test isapprox( expected_value , actual_value , rtol=1e-2)

end