@testset "Lawson Criterion Function Tests" begin

  @test isdefined(Tokamak, :lawson_criterion) == true

  actual_value = Tokamak.lawson_criterion()

  left_denom_value = Tokamak.sigma_v_hat()
  left_denom_value /= 1u"m^3/s"

  right_denom_value = sqrt( Tokamak.T_k / 1u"keV" )
  right_denom_value *= Tokamak.K_R()

  expected_value = left_denom_value
  expected_value -= right_denom_value
  expected_value = 1 / expected_value

  expected_value *= Tokamak.K_L()
  expected_value *= ( Tokamak.T_k / 1u"keV" )

  @test isapprox( expected_value , actual_value , rtol=5e-5 )

end