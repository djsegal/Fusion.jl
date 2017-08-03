"""
    setup_given_equations()

Lorem ipsum dolor sit amet.
"""
function setup_given_equations()

  given_equations = OrderedDict()

  given_equations["beta"] = OrderedDict(
    "T_k" => solved_T_k_from_beta,
    "R_0" => solved_R_0_from_T_k,
    "cur_limit" => ( troyon_beta_limit() + beta_N ),
    "max_limit" => max_beta_N
  )

  given_equations["wall"] = OrderedDict(
    "T_k" => solved_T_k_from_wall,
    "R_0" => solved_R_0_from_T_k,
    "cur_limit" => ( wall_loading_limit() + ( P_W / ( 1u"MW" / 1u"m^2" ) ) ),
    "max_limit" => max_P_W / ( 1u"MW" / 1u"m^2" )
  )

  # given_equations["heat"] = OrderedDict(
  #   "R_0" => solved_R_0_from_heat,
  #   "B_0" => solved_B_0_from_heat,
  #   "cur_limit" => ( heat_load_limit() + h_parallel ) / ( 1u"MW" / 1u"m^2" ),
  #   "max_limit" => max_h_parallel / ( 1u"MW" / 1u"m^2" )
  # )

  given_equations

end