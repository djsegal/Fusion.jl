@doc """
    magnet_Fzp(ri,rm,zi,zm,Ii,Im)

Force due to plasma.
"""
@memoize function magnet_Fzp(ri,rm,zi,zm,Ii,Im)
  (
    standard_mu_0*Ii*Im/2*((zi-zm)/(sqrt((ri+rm)^2+(zi-zm)^2))) *
    (elliptick(sqrt(4*ri*rm/((ri+rm)^2 + (zi-zm)^2))) -
    elliptice(sqrt(4*ri*rm/((ri+rm)^2+(zi-zm)^2))) *
    (1+(1/2)*(4*ri*rm/((ri+rm)^2+(zi-zm)^2))/(1-4*ri*rm/((ri+rm)^2+(zi-zm)^2))))
  )
end
