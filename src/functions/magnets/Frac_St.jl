@doc """
    Frac_St()

Fraction of steel.
"""
@memoize function Frac_St()

  cur_Frac = Area_St()

  cur_Frac /= Area_Cable()

  cur_Frac

end
