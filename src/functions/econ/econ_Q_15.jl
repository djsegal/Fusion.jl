"""
    econ_Q_15()

Total hydrogen cooling @ 15K [kW].
"""
function econ_Q_15()
  cur_p_f_part = 14.4
  cur_p_f_part *= calc_possible_values( P_F() / 1u"MW" )
  cur_p_f_part /= 500

  cur_mass_part = 35.18 * econ_cold_mass() / 10135

  cur_Q_15 = cur_p_f_part

  cur_Q_15 += cur_mass_part
  cur_Q_15 += 12.4 * econ_cold_mass() / 10135
  cur_Q_15 += 6.4 * ( ( R_0 / 1u"m" ) * ( a() / 1u"m" )^2 / 24.8 )

  cur_q_part = cur_p_f_part + cur_mass_part
  cur_q_part *= 11.4
  cur_q_part /= ( 14.4 + 35.18 )

  cur_Q_15 += cur_q_part

  cur_Q_15 += 4 * ( N_cl / 30 )

  cur_Q_15
end