function find_roots(f, a::Real, b::Real, args...;
                    no_pts::Int=101,
                    abstol::Real=10*eps(), reltol::Real=10*eps(), ## should be abstol, reltol as used.
                    kwargs...)

    @assert a != b
    @assert no_pts > 1

    ( a < b ) || ( (a, b) = (b, a) )

    work_f(x) = real(float(f(complex(x))))

    root_list = _find_recursive_roots(
      work_f, a, b, args...;
      no_pts=no_pts, abstol=abstol, reltol=reltol, kwargs...
    )

    if length(root_list) > Int(ceil( (1/4) * no_pts ))
      custom_log("Redoing root hunt on larger grid")
      return find_roots(
        f, a, b, args...;
        no_pts = 10*no_pts, abstol=abstol, reltol=reltol, kwargs...
      )
    end

    sort!(root_list)

    root_list
end

function _find_recursive_roots(f, a::Real, b::Real, args...;
                      cur_depth::Int=1,
                      no_pts::Int=101,
                      abstol::Real=10*eps(), reltol::Real=10*eps(), ## should be abstol, reltol as used.
                      kwargs...)

    cur_range = collect(linspace(a, b, no_pts))

    root_list = find_root_list(f, cur_range, abstol, reltol; kwargs...)

    isempty(root_list) && return root_list

    sub_no_pts = no_pts
    sub_no_pts /= 1 + length(root_list) / 3
    sub_no_pts /= 2 ^ ( cur_depth - 1 )
    sub_no_pts = Int(round(sub_no_pts))

    ( sub_no_pts > 1 ) || return root_list

    cur_intervals = zip(
        vcat(first(cur_range),root_list),
        vcat(root_list,last(cur_range))
    )

    for (cur_index, (cur_a, cur_b)) in enumerate(cur_intervals)
        loose_isapprox(cur_a, cur_b, abstol, reltol) && continue

        tmp_a = find_next_non_root(cur_a, f, cur_b, reltol, abstol)
        tmp_b = find_next_non_root(cur_b, f, cur_a, reltol, abstol)

        isnan(tmp_a) || isnan(tmp_b) && continue
        loose_isapprox(tmp_a, tmp_b, abstol, reltol) && continue
        ( tmp_a < tmp_b ) || continue

        if cur_depth < 5 && 1 < cur_index < length(cur_intervals)
          tmp_no_pts = no_pts
        else
          tmp_no_pts = sub_no_pts
        end

        cur_roots = _find_recursive_roots(
            f, tmp_a, tmp_b, args...;
            no_pts=tmp_no_pts, abstol=abstol, reltol=reltol,
            cur_depth=(cur_depth+1), kwargs...
        )

        append!(root_list, cur_roots)
    end

    root_list
end

function find_next_non_root(cur_root, cur_func, barrier_point, reltol, abstol)
  cur_direction = sign(barrier_point - cur_root)

  cur_adder = abstol * cur_direction
  cur_value = cur_root + cur_adder

  while sign(barrier_point - cur_value) == cur_direction
    if !loose_isapprox(cur_value, cur_root, abstol, reltol)
      cur_f = cur_func(cur_value)
      isapprox(cur_f, 0.0, atol=abstol) || break
    end

    cur_adder *= 2
    cur_value += cur_adder
  end

  is_in_range = ( sign(barrier_point - cur_value) == cur_direction )
  is_in_range || return NaN

  for tmp_value in linspace(cur_value - cur_adder, cur_value)
    ( sign(tmp_value - cur_root) == cur_direction ) || continue

    loose_isapprox(tmp_value, cur_root, abstol, reltol) && continue

    cur_f = cur_func(tmp_value)

    isapprox(cur_f, 0.0, atol=abstol) && continue

    cur_value = tmp_value
    break
  end

  ( cur_root == cur_value ) && return NaN

  cur_value
end

function find_root_list(f, cur_range::AbstractVector{T}, abstol::Real, reltol::Real; kwargs...) where T <: Real
  isempty(cur_range) && return Real[]

  cur_roots = find_bisection_roots(f, cur_range, abstol, reltol; kwargs...)
  isempty(cur_roots) || return cur_roots

  cur_root = find_order_root(f, cur_range, abstol, reltol; kwargs...)
  isnan(cur_root) && return Real[]

  cur_roots = [cur_root]
  cur_roots
end

function find_bisection_roots(f, cur_range::AbstractVector{T}, abstol::Real, reltol::Real; kwargs...) where T <: Real
  no_pts = length(cur_range)

  root_list = Real[]

  cur_values = f.(cur_range)

  filtered_cur_values = filter(isfinite, cur_values)

  isempty(filtered_cur_values) && return []

  cur_signs = map(sign, cur_values[1:end-1] .* cur_values[2:end])

  for (cur_index, cur_sign) in enumerate(cur_signs)
    isinf(cur_sign) && continue
    isnan(cur_sign) && continue

    cur_a, cur_b = cur_range[cur_index:cur_index+1]

    if iszero(cur_sign)
      iszero(cur_values[cur_index]) && push!(root_list, cur_a)

      ( cur_index == no_pts - 1 ) &&
        iszero(cur_values[cur_index+1]) && push!(root_list, cur_b)

      continue
    end

    ( cur_sign > 0 ) && continue

    cur_root = NaN
    try
      cur_root = find_zero(f, [cur_a, cur_b], FalsePosition(), maxevals=16)
      @assert isapprox(f(cur_root), 0.0, atol=abstol)
    catch
      cur_root = custom_bisection(f, cur_a, cur_b, f(cur_a), f(cur_b); abstol=abstol, kwargs...)
    end
    isnan(cur_root) || push!(root_list, cur_root)
  end

  isempty(root_list) || return root_list

  super_diff = diff(filtered_cur_values)
  cur_attempt_index = []
  if length(super_diff) == 0 || ( any(is_positive, super_diff) && any(!is_positive, super_diff) )
    cur_attempt_index = [
      findfirst(isfinite, cur_values),
      findlast(isfinite, cur_values)
    ]
  else
    if all(is_positive, filtered_cur_values) || all(!is_positive, filtered_cur_values)
      cur_is_increasing = is_positive(first(super_diff))

      first_finite_index = findfirst(isfinite, cur_values)
      last_finite_index = findlast(isfinite, cur_values)

      if cur_is_increasing
        if cur_values[first_finite_index] < 0
          cur_attempt_index = [last_finite_index]
        else
          cur_attempt_index = [first_finite_index]
        end
      else
        if cur_values[first_finite_index] < 0
          cur_attempt_index = [first_finite_index]
        else
          cur_attempt_index = [last_finite_index]
        end
      end
    else
      tmp_signs = map(sign, filtered_cur_values[1:end-1] .* filtered_cur_values[2:end])
      cur_attempt_index = findin(cur_values, filtered_cur_values[find(!is_positive, tmp_signs)])
    end
  end

  cur_min_index = indmin(map(cur_value -> isfinite(cur_value) ? abs(cur_value) : Inf, cur_values))

  push!(cur_attempt_index, cur_min_index)

  cur_attempt_index = unique(cur_attempt_index)

  for cur_index in cur_attempt_index
    cur_point = cur_range[cur_index]

    cur_diff_list = diff(cur_range)
    filter_approx!(cur_diff_list; atol=10*eps())

    @assert length(cur_diff_list) == 1
    cur_diff = cur_diff_list[1]

    if 1 < cur_index < length(cur_values)
      cur_c = cur_point
      cur_f_c = f(cur_c)

      cur_a = cur_point - cur_diff
      cur_b = cur_point + cur_diff

      cur_root = custom_bisection(f, cur_a, cur_c, f(cur_a), cur_f_c; abstol=abstol, kwargs...)
      isnan(cur_root) || return [cur_root]

      cur_root = custom_bisection(f, cur_c, cur_b, cur_f_c, f(cur_b); abstol=abstol, kwargs...)
      isnan(cur_root) || return [cur_root]
    end
  end

  []
end

function find_order_root(f, cur_range::AbstractVector{T}, abstol::Real, reltol::Real; kwargs...) where T <: Real
  min_value = first(cur_range)
  max_value = last(cur_range)

  cur_guesses = view( cur_range , (3:4:length(cur_range)-2) )

  cur_root = NaN

  for cur_guess in cur_guesses
    tmp_root = NaN

    try
      tmp_root = find_zero(
        f, cur_guess, Order8();
        maxevals=10, abstol=abstol, reltol=reltol
      )
    catch cur_error
        continue
    end

    ( min_value < tmp_root < max_value ) || continue

    isapprox(f(tmp_root), 0.0, atol=abstol) || continue

    cur_root = tmp_root

    break
  end

  cur_root
end

function loose_isapprox(first_value, second_value, atol, rtol)
  isapprox(first_value, second_value, atol=atol) && return true
  isapprox(first_value, second_value, rtol=rtol) && return true

  false
end

function custom_bisection(f, cur_a::Number, cur_b::Number, cur_f_a::Number, cur_f_b::Number, cur_flag::Bool=true; abstol::Number=10*eps(), cur_c::Number=NaN, cur_f_c::Number=NaN, cur_d::Number=NaN, cur_f_d::Number=NaN, bad_streak::Number=0, kwargs...)
  ( bad_streak > 6 ) && return NaN

  init_a = cur_a
  init_b = cur_b

  init_f_a = cur_f_a
  init_f_b = cur_f_b

  isnan(cur_c) && ( cur_c = middle(cur_a, cur_b) )
  isnan(cur_f_c) && ( cur_f_c = f(cur_c) )

  if abs(cur_f_a) < abs(cur_f_b)
    cur_a, cur_b = cur_b, cur_a
    cur_f_a, cur_f_b = cur_f_b, cur_f_a
  end

  isapprox(cur_f_a, 0.0, atol=abstol) && return cur_a
  isapprox(cur_f_b, 0.0, atol=abstol) && return cur_b
  isapprox(cur_f_c, 0.0, atol=abstol) && return cur_c
  isapprox(cur_f_d, 0.0, atol=abstol) && return cur_d

  isapprox(cur_f_a, cur_f_b, atol=abstol) && return NaN
  isapprox(cur_a, cur_b, atol=2*eps()) && return NaN

  is_bad_a = isinf(cur_f_a) || isnan(cur_f_a)
  is_bad_b = isinf(cur_f_b) || isnan(cur_f_b)
  is_bad_c = isinf(cur_f_c) || isnan(cur_f_c)
  is_bad_d = isinf(cur_f_d) || isnan(cur_f_d)

  ( !is_bad_a && !is_bad_b && cur_f_a * cur_f_b > 0 ) && return NaN

  ( is_bad_a && is_bad_b ) && return NaN

  if is_bad_a || is_bad_b || is_bad_c
    if !is_bad_d && ( isapprox(cur_c, cur_a, atol=abstol) || isapprox(cur_c, cur_b, atol=abstol) )
      cur_g = cur_d
      cur_f_g = cur_f_d
    else
      cur_g = cur_c
      cur_f_g = cur_f_c
    end

    cur_f_list = [cur_f_a, cur_f_b, cur_f_g]
    filter!(isfinite, cur_f_list)

    is_on_good_streak = isfinite(cur_f_g)
    is_on_good_streak &= abs(cur_f_g) == minimum(map(abs, cur_f_list))

    is_on_good_streak &= !isapprox(cur_f_g, cur_f_a, atol=abstol)
    is_on_good_streak &= !isapprox(cur_f_g, cur_f_b, atol=abstol)

    is_on_good_streak &= !isapprox(cur_g, cur_a, atol=abstol)
    is_on_good_streak &= !isapprox(cur_g, cur_b, atol=abstol)

    if is_on_good_streak
      bad_streak -= 1

      filter!(work_f -> work_f == cur_f_g, cur_f_list)

      second_min_f = minimum(map(abs, cur_f_list))

      ( second_min_f / abs(cur_f_g) > 8 ) &&
        ( bad_streak -= 1 )

      bad_streak = max(0, bad_streak)
    else
      if length(cur_f_list) == 1
        bad_streak += 1
      else
        bad_streak += 2
      end
    end

    cur_root = NaN

    !isapprox(cur_f_a, cur_f_g, atol=abstol) &&
      ( cur_root = custom_bisection(f, cur_a, cur_g, cur_f_a, cur_f_g; abstol=abstol, bad_streak=bad_streak, kwargs...) )

    ( isnan(cur_root) && !isapprox(cur_f_g, cur_f_b, atol=abstol) ) &&
      ( cur_root = custom_bisection(f, cur_g, cur_b, cur_f_g, cur_f_b; abstol=abstol, bad_streak=bad_streak, kwargs...) )

    return cur_root
  end

  cur_d = NaN
  cur_s = 0.0

  if !isapprox(cur_f_a, cur_f_c, atol=abstol) && !isapprox(cur_f_b, cur_f_c, atol=abstol)
    cur_term_1 = cur_f_b / ( cur_f_a - cur_f_c )
    cur_term_2 = cur_f_c / ( cur_f_a - cur_f_b )
    cur_term_3 = cur_f_a / ( cur_f_b - cur_f_c )

    cur_s += cur_a * cur_term_1 * cur_term_2
    cur_s -= cur_b * cur_term_2 * cur_term_3
    cur_s += cur_c * cur_term_3 * cur_term_1
  else
    cur_term = ( cur_b - cur_a )
    cur_term /= ( cur_f_b - cur_f_a )

    cur_s = cur_b
    cur_s -= cur_f_b * cur_term
  end

  cur_bool = ( cur_s < cur_b && cur_s < ( ( 3 * cur_a + cur_b ) / 4 ) )
  cur_bool |= ( cur_s > cur_b && cur_s > ( ( 3 * cur_a + cur_b ) / 4 ) )

  if cur_flag
    cur_diff = abs( cur_b - cur_c )
  else
    cur_diff = abs( cur_d - cur_c )
  end

  cur_bool |= abs( cur_s - cur_b ) >= ( cur_diff / 2 )
  cur_bool |= isapprox(cur_diff, 0.0, atol=abstol)

  cur_flag = cur_bool
  cur_bool && ( cur_s = middle(cur_a, cur_b) )

  cur_d = cur_c
  cur_c = cur_b

  cur_f_d = cur_f_c
  cur_f_c = cur_f_b

  cur_f_s = f(cur_s)

  if cur_f_a * cur_f_s < 0
    cur_b = cur_s
    cur_f_b = cur_f_s
  else
    cur_a = cur_s
    cur_f_a = cur_f_s
  end

  is_bad_f_a = isapprox(cur_f_a, init_f_a, atol=abstol)
  is_bad_f_b = isapprox(cur_f_b, init_f_b, atol=abstol)

  is_bad_f_a |= abs(cur_f_a) > abs(init_f_a)
  is_bad_f_b |= abs(cur_f_b) > abs(init_f_b)

  if ( is_bad_f_a && is_bad_f_b )
    bad_streak += 1
  else
    bad_streak -= 2
    bad_streak = max(0, bad_streak)
  end

  is_unchanged = isapprox(cur_a, init_a, atol=2*eps())
  is_unchanged &= isapprox(cur_b, init_b, atol=2*eps())

  if is_unchanged
    cur_c = middle(cur_a, cur_b)
    cur_f_c = f(cur_c)

    cur_root = custom_bisection(f, cur_a, cur_c, cur_f_a, cur_f_c; abstol=abstol, bad_streak=bad_streak, kwargs...)
    isnan(cur_root) || return cur_root

    cur_root = custom_bisection(f, cur_c, cur_b, cur_f_c, cur_f_b; abstol=abstol, bad_streak=bad_streak, kwargs...)
    return cur_root
  end

  custom_bisection(
    f, cur_a, cur_b, cur_f_a, cur_f_b, cur_flag;
    abstol=abstol, bad_streak=bad_streak,
    cur_c=cur_c, cur_f_c=cur_f_c,
    cur_d=cur_d, cur_f_d=cur_f_d,
    kwargs...
  )
end
